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

## Design & polish pass (round 2)

10. **Real, scannable QR codes** — the invoice previously drew a fake hash-pattern that encoded nothing. It now uses the `qrcode-generator` library (error-correction level M) and the QR is actually rendered in the invoice footer next to the map link. If the library fails to load, no fake code is shown.
11. **Dashboard now earns its space** — the decorative animated panel was replaced with a **"This Week" strip**: the next 7 days with colored counts for pickups (blue), events (rose), and returns (green); tapping a day jumps to that date in the calendar.
12. **"Today's income" is a real, distinct number** — it now sums deposits taken today + balances collected at today's pickups + late fees recorded on today's returns, instead of duplicating "today's deposits". Pickup dates are now recorded.
13. **Theme-consistent calendar & global search** — both used hardcoded dark hex values that leaked in light theme; they now use CSS variables and adapt to both themes.
14. **Analytics PIN is no longer plaintext in the source** — it's stored as a hash on the device (default `1406`), changeable from **Tools → رمز التقارير**, and only prompts once per session.
15. **Notifications no longer spam** — each reminder (late/pickup/due) fires at most once per day via a per-day dedupe key, and uses the app's own generated icon.
16. **Cancelling a rental asks for confirmation** before freeing the dress.

> **Security note:** the PIN locks are convenience latches (client-side). Real protection of the financial data must be enforced with **Firestore security rules** — the embedded Firebase config is public by design for web apps.

## Quality & hardening pass (round 3)

17. **Printed invoice is now injection-safe** — customer name, phone, notes, and dress color/code are HTML-escaped before they're written into the contract, so a value containing `<`, `>`, or `&` can no longer break the printed page.
18. **`firestore.rules` shipped** — a deployable security-rules file is included. It restricts access to the app's own collections and rejects everything else, with inline instructions and the auth-locked version to switch to. **Deploy it** (`firebase deploy --only firestore:rules`) — until you do, the database is readable/writable by anyone with the project URL.

## Usability pass (round 4)

19. **Rentals table shows the dress** — each booking row now displays the dress code and name (previously you couldn't tell which dress a booking was for without opening it).
20. **Overdue rentals are impossible to miss** — a pulsing red "متأخر X يوم" badge appears on the return-date cell of any late booking.
21. **Smart sorting** — late rentals float to the top, then active ones by nearest return date, then finished/cancelled by recency. The most urgent thing is always first.
22. **Broader search** — the rentals search now also matches phone numbers and dress codes/names, not just customer name and booking number.
23. **Top Customers table in analytics** — your 5 best customers by total paid, with rental counts and outstanding balances.
24. **Dashboard alerts name the dress** — late/upcoming alerts show the dress code so you know what to chase, not just who.
25. **Quality-of-life** — modals auto-focus their first field on desktop; phone fields bring up the numeric keyboard on mobile (with a 10-digit cap); the app toasts when the connection drops and returns.

### Verification

Every inline script is parse-checked, all `onclick` handlers resolve to defined functions, all `getElementById` targets exist, and HTML tags balance. Run the same checks anytime with a quick Node script over `index.html`.
