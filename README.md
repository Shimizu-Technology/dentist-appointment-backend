# Dentist Appointment API

This project is a **Ruby on Rails** API for scheduling dentist appointments for both adult patients and their dependents (children). It includes the following primary features:

1. **JWT-based authentication** for users and administrators.  
2. **Appointment scheduling** with conflict checks.  
3. **Dependents** (children) management for parent users.  
4. **Multiple dentists** supporting specialized care (e.g., pediatric vs. adult).  
5. **Appointment types** (e.g., “Cleaning,” “Filling,” “Checkup,” etc.) that admins can create and manage.

This README provides setup instructions, usage examples, and endpoint documentation.

---

## Table of Contents

1. [Requirements](#requirements)  
2. [Installation and Setup](#installation-and-setup)  
3. [Database Setup](#database-setup)  
4. [Running Locally](#running-locally)  
5. [Authentication](#authentication)  
6. [Endpoints](#endpoints)  
   - [Sessions (Login)](#sessions)  
   - [Appointments](#appointments)  
   - [Dependents](#dependents)  
   - [Dentists](#dentists)  
   - [Appointment Types](#appointment-types)  
   - [Admin Endpoints](#admin-endpoints)  
7. [Environment Variables](#environment-variables)  
8. [Deployment](#deployment)  
9. [Future Enhancements / Next Steps](#future-enhancements--next-steps)  

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

1. **Request a token** via the `POST /api/v1/login` endpoint by sending valid user credentials (`email` and `password`).  
2. **Receive a JWT** in the response.  
3. **Include** the token in subsequent requests in the **Authorization** header:

```
Authorization: Bearer <your_jwt_token_here>
```

**Admin vs. Regular User**:  
- An admin user (`role == "admin"`) has **full** CRUD access to Appointment Types, Dentists, and all Appointments.  
- A regular user can only manage their own appointments and dependents.

---

## Endpoints

Below is an overview of the primary endpoints, organized by resource. All requests (unless otherwise noted) require the `Authorization: Bearer <token>` header once you’ve logged in.

### Sessions

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
  - If the current user is an **admin**, returns **all** appointments.
  - If a **regular user**, returns only that user’s appointments (and their dependents’).  

  **Sample Response**:

```json
[
  {
    "id": 1,
    "user_id": 2,
    "appointment_type_id": 1,
    "dentist_id": 3,
    "dependent_id": null,
    "appointment_time": "2025-04-10T09:00:00Z",
    "status": "scheduled",
    "created_at": "...",
    "updated_at": "..."
  },
  ...
]
```

- **`GET /api/v1/appointments/:id`**  
  **Description**: Show a specific appointment by `id`.  
  **Access Rules**:  
  - Admin can see any appointment.  
  - Regular user can only see an appointment if it belongs to them or one of their dependents.

- **`POST /api/v1/appointments`**  
  **Description**: Create a new appointment for the current user (or their dependent).  
  **Request Body** (JSON example):

```json
{
  "appointment": {
    "appointment_time": "2025-04-10T09:00:00Z",
    "appointment_type_id": 1,
    "dentist_id": 3,
    "dependent_id": 5 // optional
  }
}
```

  - `appointment_type_id` must reference a valid Appointment Type.  
  - `dentist_id` must reference a valid Dentist.  
  - If `dependent_id` is omitted or `null`, the appointment is for the user themself.  

  **Response** (JSON):

```json
{
  "id": 10,
  "user_id": 2,
  "dependent_id": 5,
  "dentist_id": 3,
  "appointment_type_id": 1,
  "appointment_time": "2025-04-10T09:00:00Z",
  "status": "scheduled",
  ...
}
```

  **Conflict Check**: The system checks if the same `dentist_id` + `appointment_time` is already taken with a `status` of `"scheduled"`. If so, it returns `422` with `{ "error": "This time slot is not available." }`.

- **`PATCH/PUT /api/v1/appointments/:id`**  
  **Description**: Update an existing appointment’s fields (e.g., time, dentist).  
  **Access Rules**:  
  - Admin can update any appointment.  
  - A regular user can update only if the appointment belongs to them or their dependent.  
  **Conflict Check** is performed if the `dentist_id` or `appointment_time` changes.

- **`DELETE /api/v1/appointments/:id`**  
  **Description**: Cancels/deletes an appointment by ID.  
  **Access Rules**:  
  - Admin can delete any appointment.  
  - Regular user can delete only if it belongs to them or a dependent.  
  **On success**: returns `{ "message": "Appointment canceled." }` with `200 OK`.

---

### Dependents

All endpoints require a valid JWT token.

- **`GET /api/v1/dependents`**  
  - **Admin**: sees **all** dependents.  
  - **Regular user**: sees only **their own** dependents.

- **`POST /api/v1/dependents`**  
  Create a dependent for the currently logged-in user.  
  **Request Body**:

```json
{
  "dependent": {
    "first_name": "Child",
    "last_name": "Example",
    "date_of_birth": "2012-01-15"
  }
}
```

  **Response** (JSON):

```json
{
  "id": 5,
  "user_id": 2,
  "first_name": "Child",
  "last_name": "Example",
  "date_of_birth": "2012-01-15",
  ...
}
```

- **`PATCH/PUT /api/v1/dependents/:id`**  
  Update a dependent’s details.  
  - Admin can update **any** dependent.  
  - A regular user can update only if the dependent belongs to them.

- **`DELETE /api/v1/dependents/:id`**  
  Remove a dependent.  
  - Admin can delete any dependent.  
  - A user can only delete if the dependent belongs to them.

---

### Dentists

- **`GET /api/v1/dentists`**  
  List all dentist records.  
  - Public (no token required).

- **`GET /api/v1/dentists/:id`**  
  Show a single dentist by ID.  
  - Public (no token required).

- **`POST /api/v1/dentists`**  
  **Admin only.** Creates a new dentist record.  
  **Request Body**:

```json
{
  "dentist": {
    "first_name": "Jane",
    "last_name": "Doe",
    "specialty": "Adult Dentistry"
  }
}
```

- **`PATCH/PUT /api/v1/dentists/:id`**  
  **Admin only.** Updates a dentist’s info.

- **`DELETE /api/v1/dentists/:id`**  
  **Admin only.** Removes the dentist record.

---

### Appointment Types

- **`GET /api/v1/appointment_types`**  
  Lists all appointment types.  
  - Public access for `index` and `show`.

- **`GET /api/v1/appointment_types/:id`**  
  Shows details of one appointment type.  
  - Public.

- **`POST /api/v1/appointment_types`**  
  **Admin only.** Create a new appointment type (e.g., “Cleaning,” “Filling,” etc.).

- **`PATCH/PUT /api/v1/appointment_types/:id`**  
  **Admin only.** Update a type’s name or description.

- **`DELETE /api/v1/appointment_types/:id`**  
  **Admin only.** Remove an appointment type from the system.

---

### Admin Endpoints

Most “admin” functionality is already integrated into the resource controllers above (e.g., `DentistsController`, `AppointmentTypesController`, and the ability to see all `Appointments`). For clarity, these endpoints require `admin?`:

- **Dentists**  
  - `POST /api/v1/dentists` (create)  
  - `PATCH/PUT /api/v1/dentists/:id` (update)  
  - `DELETE /api/v1/dentists/:id` (destroy)

- **Appointment Types**  
  - `POST /api/v1/appointment_types` (create)  
  - `PATCH/PUT /api/v1/appointment_types/:id` (update)  
  - `DELETE /api/v1/appointment_types/:id` (destroy)

- **Appointments**  
  - `GET /api/v1/appointments` (admin sees **all**)  
  - `GET /api/v1/appointments/:id` (any, but admin can see all)  
  - `PATCH/PUT /api/v1/appointments/:id` (admin can update any)  
  - `DELETE /api/v1/appointments/:id` (admin can delete any)

Your separate front-end for admin users can call these endpoints, passing an **admin** user’s JWT token in the `Authorization` header. The back-end checks `current_user.admin?` to allow or deny the action.

---

## Environment Variables

- **`RAILS_MASTER_KEY`**: Rails 7 uses `config/credentials.yml.enc`. Make sure you have a valid master key for decryption when running in production or any environment that requires your app’s secrets.  
- **`DENTIST_APPOINTMENT_BACKEND_DATABASE_PASSWORD`** (optional if you store the DB password in an environment variable).  
- **`SECRET_KEY_BASE`**: Heroku or other hosting platforms often set this automatically. If self-hosting, set this manually in production.

---

## Deployment

Typical steps to deploy to a service like **Render**, **Heroku**, or a container-based platform:

1. **Set environment variables** (like `RAILS_MASTER_KEY`) in your hosting environment.

```bash
bin/rails db:migrate
```

3. **(If needed)** Precompile assets or rely on host’s build environment:

```bash
SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
```

4. **Start** the Puma server:

```bash
bin/rails server
```

For Docker-based deployments, see the provided `Dockerfile` and `.dockerignore`.

---

## Future Enhancements / Next Steps

- **Insurance Info**: The `User` model can store `provider_name`, `policy_number`, and `plan_type`. Optionally move to a separate `Insurance` model.  
- **Recurring appointments** or advanced scheduling logic.  
- **Payment Integration** (Stripe, PayPal, etc.).  
- **Email/SMS notifications** for reminders or confirmations.  
- **Advanced admin reporting** (monthly appointment volume, no-show rates, etc.).  
