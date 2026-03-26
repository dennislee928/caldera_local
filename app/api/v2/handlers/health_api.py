import operator

from aiohttp import web

import app
from app.api.v2 import security
from app.api.v2.handlers.base_api import BaseApi
from app.api.v2.schemas.caldera_info import CalderaInfoSchema

try:
    import aiohttp_apispec
except ModuleNotFoundError:
    aiohttp_apispec = None


def _noop_decorator(*_args, **_kwargs):
    def decorator(func):
        return func
    return decorator


docs_decorator = aiohttp_apispec.docs if aiohttp_apispec is not None else _noop_decorator
response_schema_decorator = (
    aiohttp_apispec.response_schema if aiohttp_apispec is not None else _noop_decorator
)


class HealthApi(BaseApi):
    def __init__(self, services):
        super().__init__()
        self._app_svc = services['app_svc']

    def add_routes(self, app: web.Application):
        router = app.router
        router.add_get('/health', security.authentication_exempt(self.get_health_info))
        router.add_get('/health-authenticated', self.get_health_info)

    @docs_decorator(tags=["health"])
    @response_schema_decorator(CalderaInfoSchema, 200)
    async def get_health_info(self, request):
        loaded_plugins_sorted = sorted(self._app_svc.get_loaded_plugins(), key=operator.attrgetter('name'))

        mapping = {
            'application': 'CALDERA',
            'version': app.get_version(),
            'plugins': loaded_plugins_sorted
        }

        return web.json_response(CalderaInfoSchema().dump(mapping))
