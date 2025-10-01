# Medicine Reminder App"MedGuard" A Comprehensive Pharmaceutical Safety Adherence Platform
### Executive Summary
MedGuard is a complete, full-stack digital ecosystem designed to connect pharmaceutical manufacturers directly with patients, enhancing safety, trust, and medication adherence. The platform consists of two main components: a patient-facing mobile application for reminders and authenticity checks, and a secure web portal for manufacturers to manage their products and generate unique, scannable digital identities. By tackling the critical issues of counterfeit drugs, medication non-adherence, and expired medicines, MedGuard provides significant value to both consumers and the pharmaceutical industry.

### The Problem in the Market
For Patients:

Medication Non-Adherence: Forgetting to take medicine on time is a major health issue.

Counterfeit Drugs: The risk of fake or substandard medicine is a serious safety concern.

Expired Medicine: Accidentally consuming expired medication poses a health risk.

Inventory Management: Unexpectedly running out of essential medication.

For Manufacturers:

Brand Erosion: Counterfeit and expired drugs in circulation damage brand reputation and trust.

Lack of Patient Connection: No direct channel to communicate with or understand the end-user.

No Usage Data: Inability to know when and where authentic products are being sold and used.

### The MedGuard Solution: A Connected Ecosystem
MedGuard bridges the gap between manufacturers and patients with a secure, two-part platform.

Patient-Facing Mobile App (Flutter): A free, user-friendly application that empowers patients to manage their health safely.

Manufacturer Web Portal (.NET MVC): A professional B2B SaaS platform for clients to control their product information and secure their supply chain.

### System Architecture
The platform is built on a modern, robust, and scalable technology stack:

Flutter Mobile App: For cross-platform (iOS & Android) patient-facing features.

.NET Web API: A secure central API that serves data to both the mobile app and the web portal.

SQL Server Database: A reliable, centralized database for all application data.

.NET Worker Service: A dedicated backend service for processing and sending real-time push notifications.

.NET MVC Web Portal: A secure, server-side web application for manufacturer clients.

### Core Features: The Patient App (Phase 1)
Secure Onboarding: Simple and secure user login using OTP.

QR Code Scanning & Authenticity Check: Users scan a QR code to instantly verify its authenticity against the manufacturer's database.

Expiry Date Safety: The app blocks the addition of expired medicines via QR scan and visually flags any existing medicine in the user's inventory that has passed its expiry date, preventing the user from setting schedules for it.

Intelligent Reminders: Users can set complex schedules and receive reliable push notifications with custom sounds.

Interactive Doses: Users can act on reminders by marking a dose as "Taken," "Skipped," or "Snoozed".

Automated Inventory Tracking: The app automatically decrements stock when a dose is taken and sends a "Low Stock" alert to prompt a refill.

Full Multilingual Support: A user interface available in English, Hindi, and Gujarati with an in-app switcher.

### Core Features: The Manufacturer Portal (Phase 2)
Secure, Role-Based Access: A Super Admin (you) can create accounts for new manufacturers. Each manufacturer has their own private admin account.

Centralized Medicine Management: A professional dashboard where manufacturers can add, view, and edit their master list of products, including multilingual details and instructions.

Batch & QR Code Generation: The core feature, allowing manufacturers to create a new batch of a product with a specific expiry date and generate thousands of unique, secure UniqueIDs.

Expiry Date Tracking: The portal clearly highlights expired batches on the "Manage QR Codes" page, helping manufacturers with supply chain visibility.

### Future Enhancements & Roadmap (V2.0 and Beyond)
The current platform is a complete and powerful V1.0. The architecture is designed to easily support future growth. Here are the next logical features to be added:

Family / Caregiver Mode: Allow a primary user to manage profiles and medications for family members (e.g., an elderly parent or a child) from one account.

Advanced Adherence Reporting: Compile the DoseLogs data into visual charts and percentage-based reports ("85% adherence in the last 30 days") that a user can share with their doctor.

Drug Interaction & Allergy Alerts: A powerful safety feature. When a user scans a new medicine, the app could cross-reference its active ingredients with other medications the user is taking or with their listed allergies to raise a warning.

Manual Entry Fallback: An option to manually enter a medicine's name for older products that may not have a QR code.

Pharmacy Integration: Features to help users find nearby pharmacies or send refill requests.

•	Here is some picture’s for Mobile app.

<img width="316" height="593" alt="image" src="https://github.com/user-attachments/assets/8291b188-151d-408e-aee3-219c35e2b23f" />
<img width="313" height="593" alt="image" src="https://github.com/user-attachments/assets/ee99ad8d-3761-4059-9801-57514a7f8a23" />
<img width="274" height="609" alt="image" src="https://github.com/user-attachments/assets/2a122215-2a32-4580-883b-6c0fad6075db" />
<img width="274" height="609" alt="image" src="https://github.com/user-attachments/assets/1c3cb0b0-c015-40e2-94da-385c348eccb6" />
<img width="287" height="557" alt="image" src="https://github.com/user-attachments/assets/a536e206-54c2-4832-a7a7-03a5589465da" />
<img width="300" height="557" alt="image" src="https://github.com/user-attachments/assets/0b6f4d2b-61a4-462a-b277-6e50a37ef585" />
<img width="308" height="634" alt="image" src="https://github.com/user-attachments/assets/7cd3089c-bbc8-429b-b862-91ae9b143338" />
<img width="286" height="634" alt="image" src="https://github.com/user-attachments/assets/f3b1bd4f-6d93-4b42-be00-46dca0a7506f" />
<img width="378" height="839" alt="image" src="https://github.com/user-attachments/assets/b92eba53-cf36-4503-940d-cb52fd40d800" />
<img width="390" height="772" alt="image" src="https://github.com/user-attachments/assets/b5e37b7e-b271-4a43-b51d-a59c7a4b4bf0" />
<img width="424" height="194" alt="image" src="https://github.com/user-attachments/assets/aaccda02-71a3-42b4-9e27-2866c979f0ec" />

•	Here is some picture’s for Web App (Manufacturer Web Portal)

<img width="940" height="434" alt="image" src="https://github.com/user-attachments/assets/425ebc0c-78e5-421d-aba7-7d46b6114a4a" />
<img width="940" height="439" alt="image" src="https://github.com/user-attachments/assets/4caca33d-577b-4d71-a5c3-064b3e162943" />
<img width="940" height="439" alt="image" src="https://github.com/user-attachments/assets/e1f06352-f5fb-41b3-8ce0-ef3541460083" />
<img width="940" height="439" alt="image" src="https://github.com/user-attachments/assets/84ff722c-28ce-47b0-ad58-9953559b1997" />
<img width="940" height="438" alt="image" src="https://github.com/user-attachments/assets/f960a18a-7a35-4314-b1d3-ba7fed36800d" />
















