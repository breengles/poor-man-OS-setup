---
description: python
---

Python style guide:

- when catching exceptions, use logger.exception("message"), not logger.error(str(e)).
- do not use mocks unless explicitly asked!
- ensure types are correct, e.g. def hello(name: str = None) is WRONG, def hello(name: str | None = None) is correct.
- use `from loguru import logger` when declaring a logger.
- prefer match + case over if + elif + else.
- using `hasattr` is typically a sign of bad design!
- functions should be used for a single purpose, avoid doing multiple things in one function.
- avoid using classes for simple functions, use functions instead.
- avoid using classes when it is not necessary, prefer functions.
- prioritize readability and simplicity over cleverness.

Python script execution:
If you need to execute a python script, firstly activate virtual environment which is typically located at the project root in `.venv` folder. If this folder does not exist then try without it.
