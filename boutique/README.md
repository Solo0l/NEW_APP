# بوتيك خلود المعني — نظام إدارة التأجير

A complete, single-file dress-rental management system for **Khulood Al-Maany Boutique** (Arabic, RTL). Open `index.html` in any modern browser — no build step, no server.

## Features

- **Dashboard** — live KPIs (active rentals, pending balances, today's deposits), overdue/upcoming alerts with one-tap WhatsApp reminders, recent rentals feed.
- **Inventory (الفساتين)** — dress catalog grouped by category with auto-generated codes (`Z-001`, `S-001`, …), photos (compressed to Base64 and stored in Firestore), live availability badges, per-dress booking history.
- **Rentals (الإيجارات)** — booking flow with auto-computed pickup/return dates from the event date, accessory checklist, double-booking conflict detection, sequential contract numbers (`RNT-000001`).
- **Pickup & returns** — payment capture at pickup (cash/transfer/card), return registration with condition and late fees.
- **Invoices (الفواتير)** — printable A4 rental contracts (Arabic), auto-archived to Firestore, rebuildable after edits.
- **Customers (العميلات)** — auto-aggregated from rentals with totals, balances, and a profile modal with full history.
- **Calendar, Analytics (PIN-protected), Studio gallery** with drag-to-reorder photo notes, **global search (⌘K)**, **WhatsApp integration**, **CSV/JSON export & import**, dark/light luxe themes, full mobile/PWA support (installable, offline shell, app PIN lock).

## Data

All data lives in **Firebase Firestore** (collections: `products`, `rentals`, `returns`, `invoices`, `galleryFolders`, `galleryPhotos`) with real-time `onSnapshot` sync across devices. Local storage only holds device preferences (theme, PIN hash, rental sequence counter, auto-backup snapshots).

## Fixes applied in this version

Compared to the previous draft of this app:

1. **Returns flow worked again** — `openReturnModal`/`confirmReturn` referenced form elements that no longer existed in the modal, crashing the flow. The modal now shows a dynamic paid/outstanding banner instead.
2. **Editing a dress no longer creates a duplicate** — `editProductId` was never set when opening the edit modal.
3. **Enabling notifications no longer crashes** — removed a call to an undefined `saveDateToCache()`.
4. **Backup import works** — rewritten to write into Firestore (`setDoc` by id) instead of the removed `STORE` API.
5. **Availability check works** — product IDs are Firestore strings; `parseInt` comparison always failed before.
6. **Analytics "collected" series is real data** — was previously hardcoded as `revenue × 0.65`.
7. **Contract numbers can't collide** — the sequence counter is re-derived from the max existing `RNT-` number on every save, and "reset" no longer wipes it.
8. **"Clear invoice archive" actually deletes** from Firestore (was a stub).
9. Deleting a dress with active rentals is blocked; names are HTML-escaped in all rendered lists; quotes in names no longer break search-result clicks; numeric fields are guarded against missing values.
