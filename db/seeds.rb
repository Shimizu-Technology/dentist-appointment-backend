# db/seeds.rb

require 'faker'

puts "Seeding data..."

# Ensure we have a clinic setting row
puts "Creating (or finding) ClinicSetting..."
setting = ClinicSetting.singleton
# e.g. open_time="09:00", close_time="17:00", open_days="1,2,3,4,5"

# -------------------------------------------------------------------
# Specialties
puts "Creating Specialties..."
general_specialty   = Specialty.find_or_create_by!(name: "General Dentistry")
pediatric_specialty = Specialty.find_or_create_by!(name: "Pediatric Dentistry")
adult_specialty     = Specialty.find_or_create_by!(name: "Adult Dentistry")

# -------------------------------------------------------------------
# Dentists
puts "Creating Dentists..."
dentist1 = Dentist.find_or_create_by!(
  first_name: "Jane",
  last_name:  "Doe",
  specialty:  adult_specialty
) do |d|
  d.image_url      = "https://images.unsplash.com/photo-1234..."
  d.qualifications = "DDS from ABC University\n15+ years experience"
end

dentist2 = Dentist.find_or_create_by!(
  first_name: "Joe",
  last_name:  "Kiddo",
  specialty:  pediatric_specialty
) do |d|
  d.image_url      = "https://images.unsplash.com/photo-5678..."
  d.qualifications = "DMD from XYZ University\nCertified Pediatric Dentist"
end

dentist3 = Dentist.find_or_create_by!(
  first_name: "Mary",
  last_name:  "Smith",
  specialty:  general_specialty
) do |d|
  d.image_url      = "https://images.unsplash.com/photo-9876..."
  d.qualifications = "DDS from State University\n10+ years experience"
end

dentists = [dentist1, dentist2, dentist3]

# -------------------------------------------------------------------
# Appointment Types
puts "Creating Appointment Types..."
cleaning_type = AppointmentType.find_or_create_by!(name: "Cleaning") do |t|
  t.description = "Routine cleaning"
  t.duration    = 30
end

filling_type = AppointmentType.find_or_create_by!(name: "Filling") do |t|
  t.description = "Cavity filling"
  t.duration    = 45
end

checkup_type = AppointmentType.find_or_create_by!(name: "Checkup") do |t|
  t.description = "General checkup"
  t.duration    = 20
end

whitening_type = AppointmentType.find_or_create_by!(name: "Teeth Whitening") do |t|
  t.description = "Professional whitening treatment"
  t.duration    = 60
end

appointment_types = [cleaning_type, filling_type, checkup_type, whitening_type]

# -------------------------------------------------------------------
# Guaranteed Admin user
puts "Creating admin@example.com..."
User.find_or_create_by!(email: "admin@example.com") do |u|
  u.password      = "password"
  u.role          = "admin"
  u.provider_name = "Delta Dental"
  u.policy_number = "AAA111"
  u.plan_type     = "PPO"
  u.phone         = "555-0001"
  u.first_name    = "Adminy"
  u.last_name     = "Example"
end

# -------------------------------------------------------------------
# Guaranteed Regular user
puts "Creating user@example.com..."
User.find_or_create_by!(email: "user@example.com") do |u|
  u.password      = "password"
  u.role          = "user"
  u.provider_name = "Guardian"
  u.policy_number = "BBB222"
  u.plan_type     = "HMO"
  u.phone         = "555-0002"
  u.first_name    = "Regular"
  u.last_name     = "User"
end

# -------------------------------------------------------------------
# 10 more Admin
puts "Creating 10 random Admin Users..."
10.times do
  User.create!(
    email:         Faker::Internet.unique.email,
    password:      "password",
    role:          "admin",
    provider_name: Faker::Company.name,
    policy_number: Faker::Alphanumeric.alpha(number: 5).upcase,
    plan_type:     ["PPO", "HMO", "POS"].sample,
    phone:         Faker::PhoneNumber.phone_number,
    first_name:    Faker::Name.first_name,
    last_name:     Faker::Name.last_name
  )
end

# -------------------------------------------------------------------
# 200 Regular
puts "Creating 200 Random Regular Users..."
users = []
200.times do
  user = User.create!(
    email:         Faker::Internet.unique.email,
    password:      "password",
    role:          "user",
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
# Dependents
puts "Creating Dependents..."
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
# Global closed days
puts "Creating example closed days..."
ClosedDay.create!(date: Date.current + 200, reason: "Staff Training")
ClosedDay.create!(date: Date.current + 300, reason: "Holiday")

# -------------------------------------------------------------------
# Dentist Unavailabilities
puts "Creating random dentist unavailabilities..."
Dentist.all.each do |dentist|
  2.times do
    date_offset = rand(150..180)
    date_obj    = Date.current + date_offset

    # skip if globally closed
    next if ClosedDay.exists?(date: date_obj)

    # skip if day not in open_days
    open_days = setting.open_days.split(',').map(&:to_i)
    wday = date_obj.wday
    next unless open_days.include?(wday)

    # 2-hour block
    start_hr = [9, 10, 12, 13, 14].sample
    end_hr   = start_hr + 2

    DentistUnavailability.create!(
      dentist_id: dentist.id,
      date:       date_obj,
      start_time: format('%02d:00', start_hr),
      end_time:   format('%02d:00', end_hr)
    )
  end
end

# -------------------------------------------------------------------
# Appointments
puts "Creating random appointments..."

# No scheduled in the past:
#   - Past => %w[completed cancelled]
#   - Future => %w[scheduled cancelled]
PAST_STATUSES   = %w[completed cancelled].freeze
FUTURE_STATUSES = %w[scheduled cancelled].freeze

users_with_dependents = users.select { |u| u.dependents.any? }

open_days = setting.open_days.split(',').map(&:to_i)
open_h, _open_m   = setting.open_time.split(':').map(&:to_i) # e.g. [9,0]
close_h, _close_m = setting.close_time.split(':').map(&:to_i) # e.g. [17,0]

# Only these minute increments
MINUTE_INCREMENTS = [0, 15, 30, 45]

def random_appointment_time_in_open_hours(open_days, open_h, close_h, in_future: false)
  # offset range: pick from [1..90] days in past or future
  offset = rand(1..90)
  base_date = in_future ? Time.current.to_date + offset : Time.current.to_date - offset

  loop do
    wday = base_date.wday
    # If wday not open or day is closed, try again
    unless open_days.include?(wday) && !ClosedDay.exists?(date: base_date)
      # increment or decrement the date to find next possible day
      base_date = in_future ? (base_date + 1) : (base_date - 1)
      next
    end

    hour   = rand(open_h..(close_h - 1))
    minute = MINUTE_INCREMENTS.sample

    return Time.zone.local(base_date.year, base_date.month, base_date.day, hour, minute, 0)
  end
end

users_with_dependents.each do |user|
  # anywhere from 0..5 appointments
  rand(0..5).times do
    # 50/50 chance of future vs. past
    is_future = [true, false].sample

    # Generate a random time
    apt_time = random_appointment_time_in_open_hours(open_days, open_h, close_h, in_future: is_future)

    # Pick appropriate statuses
    apt_status = is_future ? FUTURE_STATUSES.sample : PAST_STATUSES.sample

    appt_type  = appointment_types.sample

    begin
      Appointment.create!(
        user:             user,
        dependent:        user.dependents.sample,
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
puts " - DentistUnavailabilities: #{DentistUnavailability.count}"
puts " - Specialties: #{Specialty.count}"
puts " - ClosedDays: #{ClosedDay.count}"
