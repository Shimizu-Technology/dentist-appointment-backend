# Dentist Appointment API

This project is a **Ruby on Rails** API for scheduling dentist appointments for both adult patients and their dependents (children). It includes the following primary features:

1. **JWT-based authentication** for users and administrators.  
2. **Appointment scheduling** with conflict checks.  
3. **Dependents** (children) management for parent users.  
4. **Multiple dentists** supporting specialized care (e.g., pediatric vs. adult).  
5. **Appointment types** (e.g., “Cleaning,” “Filling,” “Checkup,” etc.) that admins can create and manage.  
6. **Admin user-management** (list all users, promote user to admin role).  
7. **Flow for Appointment Status** (e.g., “scheduled” -> “completed” -> “cancelled”)

This README provides setup instructions, usage examples, and endpoint documentation.

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
8. [Environment Variables](#environment-variables)  
9. [Deployment](#deployment)  
10. [Future Enhancements / Next Steps](#future-enhancements--next-steps)

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
  - Accepts optional query parameters such as `page`, `per_page`, or `dentist_id` (if you want to filter by dentist).

- **`GET /api/v1/appointments/:id`**  
  **Description**: Show a specific appointment by `id`.  
  - Admin can see any appointment.  
  - Regular user can only see an appointment if it belongs to them or one of their dependents.

- **`POST /api/v1/appointments`**  
  **Description**: Create a new appointment for the current user (or their dependent).  
  **Conflict Checks**:  
  - The system checks if the `dentist_id` + `appointment_time` is already taken with a `status` of `"scheduled"`.  
  - Clinic-closed days or dentist unavailability may also block the requested time.

  **Request Body** typically includes:
  ```json
  {
    "appointment": {
      "dentist_id": 1,
      "appointment_type_id": 2,
      "appointment_time": "2025-06-10T09:00:00Z",
      "dependent_id": 3,
      "notes": "...",
      "status": "scheduled"
    }
  }
  ```
  (If `dependent_id` is omitted, it defaults to the main user.)

- **`PATCH/PUT /api/v1/appointments/:id`**  
  **Description**: Update an existing appointment’s fields (e.g., time, dentist, or status).  
  - Common usage includes marking an appointment from `scheduled` to `completed`.  
  - Conflict checks still apply if you change `appointment_time` or `dentist_id`.

  **Example**:  
  ```json
  {
    "appointment": {
      "status": "completed"
    }
  }
  ```
  This would mark the appointment as completed.

- **`DELETE /api/v1/appointments/:id`**  
  **Description**: Cancels/deletes an appointment by ID.  
  - Admin can delete any appointment.  
  - Regular user can only delete if it belongs to them or a dependent.

---

### Dependents

All endpoints require a valid JWT token.

- **`GET /api/v1/dependents`**  
  - **Admin**: sees **all** dependents.  
  - **Regular user**: sees only **their own** dependents.

- **`POST /api/v1/dependents`**  
  Create a dependent for the currently logged-in user.  

- **`PATCH/PUT /api/v1/dependents/:id`**  
  Update a dependent’s details.  
  - Admin can update **any** dependent; user can only update their own.

- **`DELETE /api/v1/dependents/:id`**  
  Remove a dependent.  
  - Admin can delete any dependent; user can only delete their own.

---

### Dentists

- **`GET /api/v1/dentists`** (public)  
  Returns a list of all dentists.  

- **`GET /api/v1/dentists/:id`** (public)  
  Show details for a single dentist.  

- **`GET /api/v1/dentists/:id/availabilities`**  
  Returns the dentist’s “unavailability” blocks (dates/times they’re unavailable).

- **`POST /api/v1/dentists`** (admin only)  
  Create a new dentist record.  

- **`PATCH/PUT /api/v1/dentists/:id`** (admin only)  
  Update a dentist’s info (name, specialty, image, etc.).  

- **`DELETE /api/v1/dentists/:id`** (admin only)  
  Remove a dentist record.

---

### Appointment Types

- **`GET /api/v1/appointment_types`** (public)  
- **`GET /api/v1/appointment_types/:id`** (public)  
- **`POST /api/v1/appointment_types`** (admin only)  
- **`PATCH/PUT /api/v1/appointment_types/:id`** (admin only)  
- **`DELETE /api/v1/appointment_types/:id`** (admin only)

---

### Admin Endpoints

Most “admin” functionality is integrated into the resource controllers above (Dentists, Appointment Types, and Appointments). For clarity, these require `admin?`:

- **Dentists**  
- **Appointment Types**  
- **Appointments** (admin sees all, can update/delete all)
- **Clinic Schedules** (open/close times, closed days, dentist unavailabilities)

### Users (Admin Only)

We’ve also added routes to allow **admin** users to manage other user accounts:

- **`GET /api/v1/users`**  
  Returns a list of all users (admin-only).  

- **`POST /api/v1/users`**  
  Create a new user.  
  - If `role: "admin"` is passed in and the current user is admin, the new user can be created as admin.  
  - Otherwise, defaults to `role: "user"`.

- **`PATCH /api/v1/users/current`**  
  Update the **currently logged-in** user’s fields (e.g., first name, last name, phone, etc.).  

- **`PATCH /api/v1/users/:id/promote`**  
  Promote a user (by ID) to admin role.  
  - Returns the updated user object on success.  

- **`GET /api/v1/users/search`**  
  Search for users by name or email (admin-only).

---

## S3 Image Upload (Dentist Photos)

We use a **custom S3 uploader** for dentist photos—**not** Active Storage. The flow is:

1. **Dentist Photo** is uploaded via a `POST /api/v1/dentists/:id/upload_image` endpoint (admin-only).  
2. We use an `S3Uploader` (in `app/services/s3_uploader.rb`) to:  
   - Delete the old image if one exists  
   - Upload the new file to S3  
   - Store the resulting S3 URL in `dentists.image_url`  

### AWS Credentials & Environment Variables

Make sure you **set** the following in your `.env` or environment config:

```bash
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
AWS_REGION=ap-southeast-2  # or whatever your region is
S3_BUCKET_NAME=dentist-images
```

### Bucket Policy for Public Access

Because our S3 bucket has **Object Ownership = Bucket owner enforced**, ACL-based public reads (like `acl: 'public-read'`) are **ignored**. To actually allow the images to be loaded publicly, add a **bucket policy** (in the AWS Console under *Permissions -> Bucket Policy*) that grants `s3:GetObject` to everyone on all objects in the bucket:

```jsonc
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicReadForGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::dentist-images/*"
    }
  ]
}
```

**Important**:
- Replace `dentist-images` with your actual bucket name.
- Ensure “Block Public Access” is **off** at least for “Bucket policies.”  
- With this policy, any uploaded images become publicly viewable at their S3 URL.

### S3Uploader

Our `app/services/s3_uploader.rb` might look like this:

```ruby
# app/services/s3_uploader.rb
require 'aws-sdk-s3'

class S3Uploader
  def self.upload(file, filename)
    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )

    obj = s3.bucket(ENV['S3_BUCKET_NAME']).object(filename)
    # ACL is effectively ignored if “bucket owner enforced,” but we keep it:
    obj.upload_file(file.path, acl: 'public-read')
    obj.public_url
  end

  def self.delete(old_filename)
    s3 = Aws::S3::Resource.new(
      region: ENV['AWS_REGION'],
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )

    obj = s3.bucket(ENV['S3_BUCKET_NAME']).object(old_filename)
    obj.delete if obj.exists?
  end
end
```

### Dentist Controller Example

In `DentistsController`, the `upload_image` action might look like this:

```ruby
def upload_image
  return not_admin unless current_user.admin?

  dentist = Dentist.find(params[:id])
  file    = params[:image]
  unless file
    return render json: { error: "No image file uploaded" }, status: :unprocessable_entity
  end

  # Delete old file if present
  if dentist.image_url.present?
    old_filename = dentist.image_url.split('/').last
    S3Uploader.delete(old_filename)
  end

  # Create new filename
  original_filename = file.original_filename
  ext               = File.extname(original_filename)
  new_filename      = "dentist_#{dentist.id}_#{Time.now.to_i}#{ext}"

  # Upload to S3
  s3_url = S3Uploader.upload(file, new_filename)

  # Update dentist record with new URL
  dentist.update!(image_url: s3_url)

  render json: dentist_to_camel(dentist), status: :ok
end
```

This approach ensures each new upload overwrites the dentist’s `image_url` field, and the older S3 file gets deleted. The React frontend can then load that `image_url` directly, provided you set the **bucket policy** for public read.

---

## Environment Variables

- **`RAILS_MASTER_KEY`**: Rails 7 uses `config/credentials.yml.enc`. Make sure you have a valid master key for decryption in production or any environment that requires your app’s secrets.  
- **`DENTIST_APPOINTMENT_BACKEND_DATABASE_PASSWORD`**: If needed for your DB password.  
- **`SECRET_KEY_BASE`**: Heroku or other hosting platforms set this automatically. If self-hosting, set it manually.  
- **`AWS_ACCESS_KEY_ID`** / **`AWS_SECRET_ACCESS_KEY`** / **`AWS_REGION`** / **`S3_BUCKET_NAME`**: For uploading dentist images to Amazon S3.

---

## Deployment

Typical steps to deploy to a service like **Render**, **Heroku**, or a container-based platform:

1. **Set environment variables** (like `RAILS_MASTER_KEY`, `AWS_ACCESS_KEY_ID`, etc.) in your hosting environment or CI/CD build system.  
2. **Migrate** the database in the remote environment:

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
- **Additional Admin Tools**: e.g., searching for “next available times” across all dentists or precomputing free slots for faster lookups.  
- **Advanced admin reporting** (monthly appointment volume, no-show rates, etc.).  
- **Extended user management**: Possibly allow demotion or user deactivation, plus more robust role or permission systems.
