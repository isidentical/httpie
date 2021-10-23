from collections import OrderedDict

from urllib3.response import HTTPHeaderDict


class RequestHeadersDict(HTTPHeaderDict):
    """
    Headers are case-insensitive, and multiple values are comma-joined. A custom
    version of the `HTTPHeaderDict` to support different value types (`bytes` and `None`).
    """

    def add(self, key, value):
        """
        Set or update the given `key` with the `raw_value`. If the
        `key` header is already set, then it will update the existing
        values with the new one (the types for values must match).

        If the given `raw_value` is `None`, then the `key` for it
        will be omitted.
        """

        if value is None:
            return super().__setitem__(key, value)

        items = self.getlist(key)
        if len(items) > 0:
            first_item = items[0]
            if first_item is None:
                raise ValueError(f"Can't add a new value for already omitted {key!r} header")
            elif not isinstance(value, type(first_item)):
                raise TypeError(f"Can't mix value types for the {key!r} header")

        assert isinstance(value, (str, bytes))
        super().add(key, value)

    def __getitem__(self, key):
        """
        Retrieve a value for the given `key` header. If there are multiple,
        then they will be comma-joined and returned.
        """

        items = self.getlist(key)
        if len(items) == 0:
            raise KeyError(key)
        elif len(items) == 1:
            return items[0]

        first_item = items[0]
        if isinstance(first_item, str):
            return ", ".join(items)
        elif isinstance(first_item, bytes):
            return b", ".join(items)
        else:
            raise TypeError(f"Unsupported type: {type(first_item).__name__!r}")

    def itermerged(self):
        """Iterate over all headers."""
        for key in self:
            val = self._container[key.lower()]
            yield val[0], self[key]


class RequestJSONDataDict(OrderedDict):
    pass


class MultiValueOrderedDict(OrderedDict):
    """Multi-value dict for URL parameters and form data."""

    def __setitem__(self, key, value):
        """
        If `key` is assigned more than once, `self[key]` holds a
        `list` of all the values.

        This allows having multiple fields with the same name in form
        data and URL params.

        """
        assert not isinstance(value, list)
        if key not in self:
            super().__setitem__(key, value)
        else:
            if not isinstance(self[key], list):
                super().__setitem__(key, [self[key]])
            self[key].append(value)

    def items(self):
        for key, values in super().items():
            if not isinstance(values, list):
                values = [values]
            for value in values:
                yield key, value


class RequestQueryParamsDict(MultiValueOrderedDict):
    pass


class RequestDataDict(MultiValueOrderedDict):
    pass


class MultipartRequestDataDict(MultiValueOrderedDict):
    pass


class RequestFilesDict(RequestDataDict):
    pass
