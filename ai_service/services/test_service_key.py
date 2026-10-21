import asyncio
import json
import unittest

from services.service_key import ServiceKeyMiddleware

SECRET = "test-secret-not-real"


class _App:
    def __init__(self):
        self.calls = 0

    async def __call__(self, scope, receive, send):
        self.calls += 1
        await send({"type": "http.response.start", "status": 200, "headers": []})
        await send({"type": "http.response.body", "body": b"ok"})


async def _receive():
    return {"type": "http.request", "body": b"", "more_body": False}


def _request(middleware, path="/api/scan-document", headers=(), kind="http"):
    sent = []

    async def send(message):
        sent.append(message)

    scope = {"type": kind, "path": path, "headers": list(headers)}
    asyncio.run(middleware(scope, _receive, send))

    start = next(
        (message for message in sent if message["type"] == "http.response.start"),
        None,
    )
    body = b"".join(
        message.get("body", b"")
        for message in sent
        if message["type"] == "http.response.body"
    )

    return (start["status"] if start else None), body


class ServiceKeyMiddlewareTests(unittest.TestCase):
    def test_the_right_key_is_let_through(self):
        app = _App()
        middleware = ServiceKeyMiddleware(app, secret=SECRET)

        status, _ = _request(
            middleware, headers=[(b"x-service-key", SECRET.encode())]
        )

        self.assertEqual(status, 200)
        self.assertEqual(app.calls, 1)

    def test_a_missing_or_wrong_key_gets_403(self):
        for headers in ([], [(b"x-service-key", b"wrong")], [(b"x-service-key", b"")]):
            with self.subTest(headers=headers):
                app = _App()
                middleware = ServiceKeyMiddleware(app, secret=SECRET)

                status, body = _request(middleware, headers=headers)

                self.assertEqual(status, 403)
                self.assertEqual(json.loads(body), {"detail": "Forbidden"})
                self.assertEqual(app.calls, 0)

    def test_other_routes_need_the_key_too(self):
        for path in ("/docs", "/openapi.json", "/anything"):
            with self.subTest(path=path):
                app = _App()
                status, _ = _request(
                    ServiceKeyMiddleware(app, secret=SECRET), path=path
                )

                self.assertEqual(status, 403)
                self.assertEqual(app.calls, 0)

    def test_health_is_open(self):
        app = _App()
        status, _ = _request(ServiceKeyMiddleware(app, secret=SECRET), path="/health")

        self.assertEqual(status, 200)

    def test_header_name_is_case_insensitive(self):
        app = _App()
        status, _ = _request(
            ServiceKeyMiddleware(app, secret=SECRET),
            headers=[(b"X-Service-Key", SECRET.encode())],
        )

        self.assertEqual(status, 200)

    def test_without_a_secret_requests_are_not_checked(self):
        for secret in (None, ""):
            with self.subTest(secret=secret):
                app = _App()

                with self.assertLogs("tactilelens.ai", level="WARNING"):
                    middleware = ServiceKeyMiddleware(app, secret=secret)

                status, _ = _request(middleware)

                self.assertEqual(status, 200)

    def test_non_http_traffic_passes_through(self):
        app = _App()
        _request(ServiceKeyMiddleware(app, secret=SECRET), kind="lifespan")

        self.assertEqual(app.calls, 1)


if __name__ == "__main__":
    unittest.main()
