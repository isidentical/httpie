import functools
import string
import textwrap
from pathlib import Path
from typing import Callable, TypeVar

from httpie.cli.constants import SEPARATOR_FILE_UPLOAD
from httpie.cli.definition import options
from httpie.cli.options import Argument, ParserSpec

_COMPLETION_ENGINES = {}
T = TypeVar('T')

EXTRAS_DIR = Path(__file__).parent.parent
COMPLETION_DIR = EXTRAS_DIR / 'completion'
TEMPLATES_DIR = COMPLETION_DIR / 'templates'


def use_template(template_name: str) -> Callable[[ParserSpec], str]:
    def decorator(
        func: Callable[[ParserSpec, string.Template], str]
    ) -> Callable[[ParserSpec], str]:
        @functools.wraps(func)
        def wrapper(*args, **kwargs) -> str:
            template_file = (TEMPLATES_DIR / template_name).with_suffix(
                '.template'
            )
            completion_script_file = (COMPLETION_DIR / 'complete').with_suffix(
                '.{template_name}'
            )
            template = string.Template(template_file.read_text())

            # Dump the completion script to complete.<engine> file.
            completion_script = func(*args, template=template, **kwargs)
            completion_script_file.write_text(completion_script)

        return wrapper

    return decorator


def _fetch_named_argument(spec: ParserSpec, name: str) -> Argument:
    for group in spec.groups:
        for argument in group.arguments:
            if argument.aliases:
                targets = argument.aliases
            else:
                targets = [argument.metavar]

            if name in targets:
                return argument

    raise ValueError(f'Could not find argument with name {name}')


def _escape_zsh(text: str) -> str:
    return text.replace(':', '\\:')


def _quote_zsh(text: str) -> str:
    return f"'{text}'"


@use_template('zsh')
def zsh_completer(spec: ParserSpec, template: string.Template) -> str:
    argument_list = [
        argument
        for group in spec.groups
        for argument in group.arguments
        if not argument.is_hidden
        if not argument.is_positional
    ]

    argument_lines = []
    for argument in argument_list:
        # The argument format is the followig:
        # $prefix'$alias$has_value[$short_desc]:$metavar$:($choice_1 $choice_2)'

        prefix = ''
        declaration = []
        has_choices = 'choices' in argument.configuration

        # The format for the argument declaration canges depending on the
        # the number of aliases. For a single $alias, we'll embed it directly
        # in the declaration string, but for multiple of them, we'll use a
        # $prefix.
        if len(argument.aliases) > 1:
            prefix = '{' + ','.join(argument.aliases) + '}'
        else:
            declaration.append(argument.aliases[0])

        if not argument.is_flag:
            declaration.append('=')

        declaration.append('[' + argument.short_help + ']')

        if 'metavar' in argument.configuration:
            metavar = argument.metavar
        elif has_choices:
            # Choices always require a metavar, so even if we don't have one
            # we can generate it from the argument aliases.
            metavar = (
                max(argument.aliases, key=len)
                .lstrip('-')
                .replace('-', '_')
                .upper()
            )
        else:
            metavar = None

        if metavar:
            # Strip out any whitespace, and escape any characters that would
            # conflict with the shell.
            metavar = _escape_zsh(metavar.strip(' '))
            declaration.append(f':{metavar}:')

        if has_choices:
            declaration.append('(' + ' '.join(argument.choices) + ')')

        argument_lines.append(prefix + f"{_quote_zsh(''.join(declaration))}")

    # Top level conditions for REQUEST_ITEMS. Each condition
    # is going to mapped to an if statement with the action
    # as its body.
    condition_to_action = {}
    full_description_table = []

    request_items = _fetch_named_argument(spec, 'REQUEST_ITEM')
    for option_name, _, operator, desc in request_items.nested_options:
        if operator == SEPARATOR_FILE_UPLOAD:
            action = '_files'
        else:
            action = '_message "$name {option_name}"'

        condition_to_action[operator] = action
        full_description_table.append(f'{_escape_zsh(operator)}:{desc}')

    conditions = [
        textwrap.dedent(
            f"""
        elif compset -P '{operator}'; then
            {action}
        """
        ).strip()
        for operator, action in condition_to_action.items()
    ]

    return template.safe_substitute(
        conditions='\n'.join(conditions),
        full_descriptions='\n'.join(map(_quote_zsh, full_description_table)),
        argument_lines=' \\\n'.join(argument_lines),
    )


if __name__ == '__main__':
    zsh_completer(options)
