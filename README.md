# Dentist Appointment API

This project is a **Ruby on Rails** API for scheduling dentist appointments for both adult patients and their dependents (children). It includes the following primary features:

1. **JWT-based authentication** for users and administrators.  
2. **Appointment scheduling** with conflict checks.  
3. **Dependents** (children) management for parent users.  
4. **Multiple dentists** supporting specialized care (e.g., pediatric vs. adult).  
5. **Appointment types** (e.g., “Cleaning,” “Filling,” “Checkup,” etc.) that admins can create and manage.  
6. **Admin user-management** (list all users, promote user to admin role, invite users by email).  
7. **Flow for Appointment Status** (e.g., “scheduled” → “completed” → “canceled”).  
8. **Email invitations** for new users, using **SendGrid**.  
9. **SMS Reminders** via **ClickSend**, with a scheduled cron job to automatically send reminders.

---

## Table of Contents

1. [Requirements](#requirements)  
2. [Installation and Setup](#installation-and-setup)  
3. [Database Setup](#database-setup)  
4. [Running Locally](#running-locally)  
5. [Authentication](#authentication)  
6. [Endpoints](#endpoints)  
   - [Sessions (Login)](#sessions-login)  
   - [Appointments](#appointments)  
   - [Dependents](#dependents)  
   - [Dentists](#dentists)  
   - [Appointment Types](#appointment-types)  
   - [Admin Endpoints](#admin-endpoints)  
   - [Users (Admin Only)](#users-admin-only)  
7. [S3 Image Upload (Dentist Photos)](#s3-image-upload-dentist-photos)
8. [Email Invitations (SendGrid)](#email-invitations-sendgrid)
9. [SMS Reminders (ClickSend)](#sms-reminders-clicksend)
10. [Environment Variables](#environment-variables)  
11. [Deployment](#deployment)  
12. [Hosting and Links](#hosting-and-links)
13. [Future Enhancements / Next Steps](#future-enhancements--next-steps)

---

## Requirements

- **Ruby 3.2+** (as specified in `.ruby-version`)  
- **Rails 7.2+**  
- **PostgreSQL** for the database  
- **Bundler** for managing gems  

---

## Installation and Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/your-organization/dentist-appointment-backend.git
   cd dentist-appointment-backend
   ```

2. **Install Ruby gems**:

   ```bash
   bundle install
   ```

---

## Database Setup

1. **Create and migrate the database**:

   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

2. **(Optional) Seed the database** if you have seed data in `db/seeds.rb`:

   ```bash
   bin/rails db:seed
   ```

---

## Running Locally

To start the Rails server (by default on port `3000`):

```bash
bin/rails server
```

You can then access the API at:  
**http://localhost:3000**

---

## Authentication

This API uses **JWT-based authentication**. To authenticate:

1. **Request a token** via `POST /api/v1/login` with valid user credentials (`email`, `password`).  
2. **Receive a JWT** in the response.  
3. **Include** that token in subsequent requests in the **Authorization** header:

```
Authorization: Bearer <your_jwt_token_here>
```

**Admin vs. Regular User**:  
- An admin user (`role == "admin"`) has **full** CRUD access to Appointment Types, Dentists, all Appointments, and user management.  
- A regular user can only manage their own appointments and dependents.

---

## Endpoints

Below is an overview of the primary endpoints, organized by resource. All requests (unless otherwise noted) require the `Authorization: Bearer <token>` header once you’ve logged in.

### Sessions (Login)

- **`POST /api/v1/login`**  
  **Description**: Logs in a user and returns a JWT token.  
  **Request Body** (JSON):

  ```json
  {
    "email": "user@example.com",
    "password": "password123"
  }
  ```

  **Response** (JSON):

  ```json
  {
    "jwt": "<your_jwt_here>",
    "user": {
      "id": 1,
      "email": "user@example.com",
      "role": "user"
      // ... other user fields
    }
  }
  ```

  **Notes**:  
  - This endpoint is **public** (no token required).  
  - Use the returned `jwt` for subsequent requests.

---

### Appointments

All endpoints below **require** a valid JWT token in the `Authorization` header.

- **`GET /api/v1/appointments`**  
  **Description**: Returns all appointments.  
  - If the current user is **admin**, returns **all** appointments.
  - If a **regular user**, returns only that user’s appointments (and their dependents’).  
  - Accepts optional query parameters such as `page`, `per_page`, `dentist_id`, etc.

- **`GET /api/v1/appointments/:id`**  
  Show a specific appointment by `id`.  
  - Admin sees any appointment.  
  - Regular user only sees appointments for themselves or their dependent.

- **`POST /api/v1/appointments`**  
  Create a new appointment for the current user (or their dependent).  
  - Checks conflicts (dentist availability, closed days, etc.).

- **`PATCH/PUT /api/v1/appointments/:id`**  
  Update an existing appointment’s fields (e.g., changing status from “scheduled” to “completed”).

- **`DELETE /api/v1/appointments/:id`**  
  Cancels or deletes an appointment by ID.

---

### Dependents

- **`GET /api/v1/dependents`**  
  Admin sees all; a user sees only their own.
- **`POST /api/v1/dependents`**  
- **`PATCH/PUT /api/v1/dependents/:id`**  
- **`DELETE /api/v1/dependents/:id`**  

---

### Dentists

- **`GET /api/v1/dentists`**  
  Public route listing all dentists.
- **`GET /api/v1/dentists/:id`**  
  Show a single dentist.
- **`GET /api/v1/dentists/:id/availabilities`**  
  Returns the “unavailable” blocks for that dentist.
- **Admin-only**: Create, Update, Destroy, plus `POST /api/v1/dentists/:id/upload_image` for uploading a dentist photo.

---

### Appointment Types

- **`GET /api/v1/appointment_types`** (public)  
- **Admin-only**: Create, Update, Destroy

---

### Admin Endpoints

- **`GET /api/v1/users`** (lists all users)  
- **`PATCH /api/v1/users/:id/promote`** (promote a user to admin)  
- **Search** users by name/email  
- **Manage** closed days, clinic schedule, dentist unavailabilities, etc.

---

### Users (Admin Only)

**Invitation Flow** for new users with emails. See [Email Invitations](#email-invitations-sendgrid).

---

## S3 Image Upload (Dentist Photos)

We use a **custom S3 uploader** rather than Active Storage. For details, see [S3 Image Upload (Dentist Photos)](#s3-image-upload-dentist-photos) above.

---

## Email Invitations (SendGrid)

When an admin creates a new user with an email, the system can send them an “invitation” via SendGrid. For more details, see [Email Invitations (SendGrid)](#email-invitations-sendgrid) above.

---

## SMS Reminders (ClickSend)

We’ve integrated **ClickSend** to automatically send appointment reminders via SMS. By default:

- Reminders are scheduled to go out at **8:00 AM the day before** an appointment, and **8:00 AM the day of** the appointment.  
- A **cron job** (see next section) runs daily, checks for any pending reminders, and sends them via ClickSend.

### Manually Running Reminders

If you need to trigger reminders manually:

1. **Rails console** locally:
   ```ruby
   SendAppointmentRemindersJob.perform_now
   ```

2. **Render’s interactive shell**:
   ```bash
   bin/rails runner "SendAppointmentRemindersJob.perform_now"
   ```

This executes the job immediately.

---

## Environment Variables

- **`RAILS_MASTER_KEY`**: For decrypting `config/credentials.yml.enc`.  
- **Database variables** (like `DATABASE_URL` or `PG*` from your hosting):  
  - For connecting to your Render PostgreSQL instance.  
- **ClickSend** credentials:  
  - `CLICKSEND_USERNAME`  
  - `CLICKSEND_API_KEY`  
- **SendGrid** credentials:  
  - `SENDGRID_API_KEY`  
  - `SENDGRID_FROM_EMAIL`  

You also need the usual `SECRET_KEY_BASE` or other standard Rails env vars depending on your hosting environment.

---

## Deployment

1. **Set environment variables** in your hosting environment (Render, Heroku, etc.) so that Rails can connect to your DB, has the master key, etc.
2. **Migrate** the database in the remote environment:

   ```bash
   bin/rails db:migrate
   ```

3. **(If needed)** Precompile assets:

   ```bash
   SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
   ```

4. **Start** Puma or another server:

   ```bash
   bin/rails server
   ```

---

## Hosting and Links

- **Backend** is hosted on Render (Web Service):  
  [Render Web Service Dashboard](https://dashboard.render.com/web/srv-ctqi5i5svqrc73coi1mg/settings)

- **PostgreSQL Database** is on Render:  
  [isa-dental-db on Render](https://dashboard.render.com/d/dpg-ctqi6elds78s73dd3t50-a)

- **Cron Job** (for automated reminders) is on Render as well:  
  [Cron job on Render](https://dashboard.render.com/cron/crn-cu07un9opnds738lpeb0/settings)

- **Frontend** is hosted on Netlify:  
  [isa-dental-appt Netlify Dashboard](https://app.netlify.com/sites/isa-dental-appt/overview)

---

## Future Enhancements / Next Steps

- **Insurance Info**: Possibly move user insurance fields to a separate `Insurance` model.  
- **Recurring Appointments**: Add advanced scheduling logic.  
- **Payment Integration**: e.g. Stripe or PayPal.  
- **More Admin Tools**: e.g. monthly reporting, next available time searches, etc.  
- **Advanced user management**: Demotions, user deactivation, or additional roles.
