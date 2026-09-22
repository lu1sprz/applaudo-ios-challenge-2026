# NetworkLayer

A pre-built networking module that abstracts the HTTP communication layer for the iOS challenge project.  
It is backed by [Moya](https://github.com/Moya/Moya) and [Combine](https://developer.apple.com/documentation/combine).

---

## Purpose

This module is the single entry point for all API communication in the app.  
Your task is to use the types and protocols already defined here to implement the features required by the challenge — **you should not need to modify the core networking infrastructure**, but you are welcome to extend it if you have a good reason.

---

## What's Inside

| Path | Description |
|---|---|
| `Sources/Networking/` | Core request executor and endpoint protocol |
| `Sources/Targets/` | Concrete API endpoint definitions |
| `Sources/Models/` | Shared model types used across the layer |
| `Sources/Services/` | Service classes that orchestrate requests — **you will work here** |
| `Sources/Extensions/` | Utility extensions for Moya and Foundation types |

---

## API Key Setup

This module connects to [The Cat API](https://thecatapi.com). You need a free API key to make authenticated requests.

1. Generate your key at:  
   **https://developers.thecatapi.com/view-account/ylX4blBYT9FaoVd6OhvR?report=FJkYOq9tW**

2. Once you have the key, replace the placeholder in `ApplaudoChallenge/.env`:

```sh
CAT_API_KEY=YOUR-API-KEY
```

> Requests made without a valid key will be rate-limited and may fail.

---

## Expected Usage

Consumers of this module should:

1. Define a new target conforming to `NetworkingTargetType` (see `CatInformationTarget` as a reference).
2. Create a service in the `Services/` folder that holds a `NetworkingRequesterType` dependency and exposes Combine publishers to the rest of the app.
3. Inject the service into the relevant view model or coordinator.

---

## Running Tests

Unit tests live in `NetworkLayerTest/`. At a minimum, cover the success path, server error mapping, and decoding failures for any service you implement.
