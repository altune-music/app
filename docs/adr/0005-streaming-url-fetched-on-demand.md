# Streaming URL fetched on-demand

When a song is queued for playback, the app does not store the streaming URL in the `Song` model. URLs are fetched on-demand via the API when playback is actually needed.

Streaming URLs expire. Storing a stale URL leads to broken playback later. Fetching fresh each time ensures reliability at the cost of an extra API call.
