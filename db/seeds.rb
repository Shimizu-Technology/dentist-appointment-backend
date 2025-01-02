# db/seeds.rb

require 'faker'

puts "Seeding data..."

# -------------------------------------------------------------------
# Specialty
puts "Creating Specialties..."
general_specialty   = Specialty.create!(name: "General Dentistry")
pediatric_specialty = Specialty.create!(name: "Pediatric Dentistry")
adult_specialty     = Specialty.create!(name: "Adult Dentistry")

# -------------------------------------------------------------------
# Dentists
puts "Creating Dentists..."
dentist1 = Dentist.create!(
  first_name: "Jane",
  last_name:  "Doe",
  specialty:  adult_specialty,
  image_url:  "https://images.unsplash.com/photo-1234...",
  qualifications: "DDS from ABC University\n15+ years experience"
)

dentist2 = Dentist.create!(
  first_name: "Joe",
  last_name:  "Kiddo",
  specialty:  pediatric_specialty,
  image_url:  "https://images.unsplash.com/photo-5678...",
  qualifications: "DMD from XYZ University\nCertified Pediatric Dentist"
)

dentist3 = Dentist.create!(
  first_name: "Mary",
  last_name:  "Smith",
  specialty:  general_specialty,
  image_url:  "https://images.unsplash.com/photo-9876...",
  qualifications: "DDS from State University\n10+ years experience"
)

# -------------------------------------------------------------------
# Appointment Types
puts "Creating Appointment Types..."
cleaning_type = AppointmentType.create!(
  name: "Cleaning",
  description: "Routine cleaning",
  duration: 30
)

filling_type = AppointmentType.create!(
  name: "Filling",
  description: "Cavity filling",
  duration: 45
)

checkup_type = AppointmentType.create!(
  name: "Checkup",
  description: "General checkup",
  duration: 20
)

whitening_type = AppointmentType.create!(
  name: "Teeth Whitening",
  description: "Professional whitening treatment",
  duration: 60
)

appointment_types = [cleaning_type, filling_type, checkup_type, whitening_type]
dentists          = [dentist1, dentist2, dentist3]

# -------------------------------------------------------------------
# Guaranteed Admin user
puts "Creating guaranteed admin@example.com account..."
User.create!(
  email: "admin@example.com",
  password: "password",
  role: "admin",
  provider_name: "Delta Dental",
  policy_number: "AAA111",
  plan_type: "PPO",
  phone: "555-0001",
  first_name: "Adminy",
  last_name: "Example"
)

# -------------------------------------------------------------------
# Guaranteed Regular user
puts "Creating guaranteed user@example.com account..."
User.create!(
  email: "user@example.com",
  password: "password",
  role: "user",
  provider_name: "Guardian",
  policy_number: "BBB222",
  plan_type: "HMO",
  phone: "555-0002",
  first_name: "Regular",
  last_name: "User"
)

# -------------------------------------------------------------------
# Admin Users
puts "Creating 10 Random Admin Users..."
10.times do
  User.create!(
    email:       Faker::Internet.unique.email,
    password:    "password",  # default password
    role:        "admin",
    provider_name: Faker::Company.name,
    policy_number: Faker::Alphanumeric.alpha(number: 5).upcase,
    plan_type:     ["PPO", "HMO", "POS"].sample,
    phone:         Faker::PhoneNumber.phone_number,
    first_name:    Faker::Name.first_name,
    last_name:     Faker::Name.last_name
  )
end

# -------------------------------------------------------------------
# Regular Users (Parents)
puts "Creating 200 Random Regular Users..."
users = []
200.times do
  user = User.create!(
    email:       Faker::Internet.unique.email,
    password:    "password",
    role:        "user",
    provider_name: Faker::Company.name,
    policy_number: Faker::Alphanumeric.alpha(number: 5).upcase,
    plan_type:     ["PPO", "HMO", "POS"].sample,
    phone:         Faker::PhoneNumber.phone_number,
    first_name:    Faker::Name.first_name,
    last_name:     Faker::Name.last_name
  )
  users << user
end

# -------------------------------------------------------------------
# Create Dependents (2 to 4 for each user)
puts "Creating Dependents for each user..."
users.each do |user|
  rand(2..4).times do
    user.dependents.create!(
      first_name:    Faker::Name.first_name,
      last_name:     user.last_name,  
      date_of_birth: Faker::Date.birthday(min_age: 1, max_age: 17)
    )
  end
end

# -------------------------------------------------------------------
# DentistAvailabilities for each dentist
puts "Creating Dentist Availabilities..."
# Dentist 1:
DentistAvailability.create!(dentist: dentist1, day_of_week: 1, start_time: "09:00", end_time: "17:00") # Mon
DentistAvailability.create!(dentist: dentist1, day_of_week: 2, start_time: "09:00", end_time: "17:00") # Tue
DentistAvailability.create!(dentist: dentist1, day_of_week: 3, start_time: "09:00", end_time: "17:00") # Wed
DentistAvailability.create!(dentist: dentist1, day_of_week: 4, start_time: "09:00", end_time: "17:00") # Thu
DentistAvailability.create!(dentist: dentist1, day_of_week: 5, start_time: "09:00", end_time: "15:00") # Fri

# Dentist 2:
DentistAvailability.create!(dentist: dentist2, day_of_week: 1, start_time: "10:00", end_time: "18:00") # Mon
DentistAvailability.create!(dentist: dentist2, day_of_week: 2, start_time: "10:00", end_time: "18:00") # Tue
DentistAvailability.create!(dentist: dentist2, day_of_week: 4, start_time: "10:00", end_time: "18:00") # Thu
DentistAvailability.create!(dentist: dentist2, day_of_week: 5, start_time: "10:00", end_time: "16:00") # Fri

# Dentist 3:
DentistAvailability.create!(dentist: dentist3, day_of_week: 1, start_time: "08:00", end_time: "16:00") # Mon
DentistAvailability.create!(dentist: dentist3, day_of_week: 2, start_time: "08:00", end_time: "16:00") # Tue
DentistAvailability.create!(dentist: dentist3, day_of_week: 3, start_time: "12:00", end_time: "20:00") # Wed
DentistAvailability.create!(dentist: dentist3, day_of_week: 4, start_time: "08:00", end_time: "16:00") # Thu
DentistAvailability.create!(dentist: dentist3, day_of_week: 5, start_time: "09:00", end_time: "12:00") # Fri

# -------------------------------------------------------------------
# Appointments
puts "Creating random Appointments..."

def random_weekday_future_time(days_in_future = 90)
  loop do
    day_offset = rand(1..days_in_future)
    hour       = rand(8..17)
    date       = Faker::Time.forward(days: day_offset, period: :day).change(hour: hour)
    # skip weekends
    unless date.saturday? || date.sunday?
      return date
    end
  end
end

def random_weekday_past_time(days_in_past = 90)
  loop do
    day_offset = rand(1..days_in_past)
    hour       = rand(8..17)
    date       = Faker::Time.backward(days: day_offset, period: :day).change(hour: hour)
    # skip weekends
    unless date.saturday? || date.sunday?
      return date
    end
  end
end

status_options = %w[scheduled completed cancelled]

users.each do |user|
  user_dependents = user.dependents
  next if user_dependents.empty?

  rand(0..5).times do
    # 50% future, 50% past
    apt_time   = [true, false].sample ? random_weekday_future_time : random_weekday_past_time
    apt_status = status_options.sample
    appt_type  = appointment_types.sample

    begin
      Appointment.create!(
        user:             user,
        dependent:        user_dependents.sample,
        dentist:          dentists.sample,
        appointment_type: appt_type,
        appointment_time: apt_time,
        status:           apt_status,
        notes:            Faker::Lorem.sentence(word_count: 6)
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "  -> Skipping an invalid appointment: #{e.message}"
    end
  end
end

puts "Seeding complete!"
puts "--------------------------------------------------"
puts "Summary:"
puts " - Dentists: #{Dentist.count}"
puts " - Admin Users: #{User.where(role: 'admin').count}"
puts " - Regular Users: #{User.where(role: 'user').count}"
puts " - Dependents: #{Dependent.count}"
puts " - AppointmentTypes: #{AppointmentType.count}"
puts " - Appointments: #{Appointment.count}"
puts " - DentistAvailabilities: #{DentistAvailability.count}"
puts " - Specialties: #{Specialty.count}"
