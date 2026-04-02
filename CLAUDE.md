# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Dart package (`async_queue`) that ensures async tasks execute sequentially in FIFO order. Published on pub.dev. SDK constraint: `>=2.18.2 <4.0.0`.

## Commands

```bash
# Get dependencies
dart pub get

# Run all tests
dart test

# Run a single test file
dart test test/async_queue_test.dart

# Analyze code
dart analyze

# Format code
dart format .
```

## Architecture

The queue is implemented as a **singly linked list** of `AsyncNode` objects, not a `List` or `Queue` collection.

- **`AsyncQueue`** (`lib/src/async_queue_base.dart`) — The core class. Has two modes:
  - **Normal mode** (`AsyncQueue()`) — Jobs are added, then `start()` is called explicitly to process them.
  - **Auto mode** (`AsyncQueue.autoStart()`) — Jobs execute immediately upon being added; subsequent jobs wait their turn.
- **`AsyncNode`** (`lib/src/async_node.dart`) — A linked-list node wrapping a single `AsyncJob`. Tracks `JobState` (pending/running/done/failed/pendingRetry) and retry count. The `AsyncNode` class is hidden from the public API via `export ... hide AsyncNode`.
- **`AsyncJob` typedef** (`lib/src/typedef.dart`) — `Function(PreviousResult)`. Each job receives the return value of the previous job, enabling chaining.
- **`QueueEvent` / `QueueEventType`** (`lib/src/queue_event.dart`) — Event system for observing queue lifecycle (start, end, beforeJob, afterJob, retry, closed, etc.).
- **Exceptions** (`lib/src/exceptions.dart`) — `ClosedQueueException`, `DuplicatedLabelException`, `InvalidJobLabelException`.

Key behaviors: jobs can have labels for deduplication (`allowDuplicate`/`throwIfDuplicate` flags), retry support via `retry()` method with configurable max retries (`-1` for infinite), and `stop()`/`close()` for queue lifecycle control.

## Library Barrel

`lib/async_queue.dart` re-exports all public API. The `AsyncNode` class is intentionally hidden from consumers.
