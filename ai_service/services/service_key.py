"""Require the shared service key on every AI service request.

The AI service must only be reachable through the Node backend. Node
sends the AI_SERVICE_SECRET value in the X-Service-Key header; any other
request gets 403. /health stays open for platform health checks.

Written as plain ASGI so it has no dependency beyond the standard library.
"""

import hmac
import json
import logging
from typing import Any, Awaitable, Callable

PUBLIC_PATHS = frozenset({"/health"})

HEADER_NAME = b"x-service-key"

logger = logging.getLogger("tactilelens.ai")

Receive = Callable[[], Awaitable[dict[str, Any]]]
Send = Callable[[dict[str, Any]], Awaitable[None]]


class ServiceKeyMiddleware:
    def __init__(
        self,
        app: Callable[[dict[str, Any], Receive, Send], Awaitable[None]],
        secret: str | None,
        public_paths: frozenset[str] = PUBLIC_PATHS,
    ) -> None:
        self.app = app
        self.secret = (secret or "").encode()
        self.public_paths = public_paths

        if not self.secret:
            logger.warning(
                "AI_SERVICE_SECRET is not set: requests are not "
                "authenticated. Use this only for local development."
            )

    async def __call__(
        self,
        scope: dict[str, Any],
        receive: Receive,
        send: Send,
    ) -> None:
        if (
            not self.secret
            or scope.get("type") != "http"
            or scope.get("path") in self.public_paths
            or self._has_valid_key(scope)
        ):
            await self.app(scope, receive, send)
            return

        body = json.dumps({"detail": "Forbidden"}).encode()

        await send(
            {
                "type": "http.response.start",
                "status": 403,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"content-length", str(len(body)).encode()),
                ],
            }
        )
        await send({"type": "http.response.body", "body": body})

    def _has_valid_key(self, scope: dict[str, Any]) -> bool:
        given = b""

        for name, value in scope.get("headers") or []:
            if name.lower() == HEADER_NAME:
                given = value
                break

        return hmac.compare_digest(given, self.secret)
