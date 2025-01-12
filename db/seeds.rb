# File: db/seeds.rb

require 'faker'

puts "Seeding data..."

# -------------------------------------------------------------------
# 1) DAY-OF-WEEK CLINIC SETTINGS
# -------------------------------------------------------------------
puts "Creating/Updating ClinicDaySettings for each day of the week..."
(0..6).each do |wday|
  case wday
  when 0 # Sunday
    is_open        = false
    open_time_str  = "00:00"
    close_time_str = "00:00"
  when 6 # Saturday
    is_open        = true
    open_time_str  = "10:00"
    close_time_str = "14:00"
  else
    # Monday..Friday
    is_open        = true
    open_time_str  = "09:00"
    close_time_str = "17:00"
  end

  ClinicDaySetting.find_or_create_by!(day_of_week: wday) do |ds|
    ds.is_open    = is_open
    ds.open_time  = open_time_str
    ds.close_time = close_time_str
  end
end

# -------------------------------------------------------------------
# 2) SPECIALTIES
# -------------------------------------------------------------------
puts "Creating Specialties..."
general_specialty   = Specialty.find_or_create_by!(name: "General Dentistry")
pediatric_specialty = Specialty.find_or_create_by!(name: "Pediatric Dentistry")
adult_specialty     = Specialty.find_or_create_by!(name: "Adult Dentistry")

# -------------------------------------------------------------------
# 3) DENTISTS
# -------------------------------------------------------------------
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
# 4) APPOINTMENT TYPES
# -------------------------------------------------------------------
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
# 5) USERS (Admin + Regular + Phone-Only)
# -------------------------------------------------------------------
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

puts "Creating 20 Phone-Only Users..."
phone_only_users = []
20.times do
  user = User.create!(
    role:       'phone_only',
    phone:      Faker::PhoneNumber.phone_number,
    first_name: Faker::Name.first_name,
    last_name:  Faker::Name.last_name
  )
  phone_only_users << user
end

users += phone_only_users

# -------------------------------------------------------------------
# 6) CREATE CHILD USERS (DEPENDENTS) with NO phone/email
#    (Approach #2: store real contact info only in parent’s record)
# -------------------------------------------------------------------
puts "Creating child (dependent) users for each regular user..."
all_regular_users = users.select { |u| u.role == 'user' }  # omit phone_only or admin

all_regular_users.each do |parent|
  # Randomly create between 0..3 children
  rand(0..3).times do
    User.create!(
      is_dependent:    true,
      parent_user_id:  parent.id,
      role:            'phone_only',  # ensures we skip email/password validations
      phone:           nil,           # no direct phone; parent's phone is used
      email:           nil,           # no direct email; parent's email is used
      first_name:      Faker::Name.first_name,
      last_name:       parent.last_name,
      date_of_birth:   Faker::Date.birthday(min_age: 1, max_age: 17)
    )
  end
end

# -------------------------------------------------------------------
# 7) CLOSED DAYS
# -------------------------------------------------------------------
puts "Creating example closed days..."
ClosedDay.create!(date: Date.current + 200, reason: "Staff Training")
ClosedDay.create!(date: Date.current + 300, reason: "Holiday")

# -------------------------------------------------------------------
# 8) DENTIST UNAVAILABILITIES
# -------------------------------------------------------------------
puts "Creating random dentist unavailabilities..."
Dentist.all.each do |dentist|
  2.times do
    date_offset = rand(150..180)
    date_obj    = Date.current + date_offset

    # skip if date is globally closed
    next if ClosedDay.exists?(date: date_obj)

    # skip if day_of_week is not open
    wday = date_obj.wday
    ds = ClinicDaySetting.find_by(day_of_week: wday)
    next if ds.nil? || !ds.is_open

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
# 9) APPOINTMENTS
# -------------------------------------------------------------------
puts "Creating random appointments..."

PAST_STATUSES   = %w[completed cancelled].freeze
FUTURE_STATUSES = %w[scheduled cancelled].freeze

all_regular_users = User.where(role: 'user', is_dependent: false)

def random_appointment_time
  max_tries = 365
  tries     = 0
  in_future = [true, false].sample
  offset_days = rand(1..90)
  base_date = in_future ? Date.current + offset_days : Date.current - offset_days

  loop do
    tries += 1
    raise "Cannot find a valid open day/time after #{max_tries} tries." if tries > max_tries

    # 1) Skip if globally closed
    if ClosedDay.exists?(date: base_date)
      base_date = in_future ? base_date + 1.day : base_date - 1.day
      next
    end

    # 2) Check if day_of_week is open
    ds = ClinicDaySetting.find_by(day_of_week: base_date.wday)
    if ds&.is_open
      open_h, open_m   = ds.open_time.split(':').map(&:to_i)
      close_h, close_m = ds.close_time.split(':').map(&:to_i)

      hours_range = (open_h...close_h).to_a
      if hours_range.any?
        chosen_hour = hours_range.sample
        chosen_min  = [0, 15, 30, 45].sample

        return Time.zone.local(
          base_date.year, base_date.month, base_date.day,
          chosen_hour, chosen_min, 0
        )
      end
    end

    # If we can't find a valid slot, step forward/backward a day and retry
    base_date = in_future ? base_date + 1.day : base_date - 1.day
  end
end

all_regular_users.each do |user|
  # If you also create appointments for child users:
  child_users_for_this_parent = User.where(parent_user_id: user.id, is_dependent: true)

  rand(1..5).times do
    apt_time   = random_appointment_time
    is_future  = apt_time >= Time.current
    apt_status = is_future ? FUTURE_STATUSES.sample : PAST_STATUSES.sample
    appt_type  = AppointmentType.all.sample  # or any array you have

    chosen_child = (child_users_for_this_parent.any? && rand(2).zero?) ? child_users_for_this_parent.sample : nil

    begin
      Appointment.create!(
        user_id:          chosen_child&.id || user.id,   # maybe it’s for the child, maybe for the parent
        dentist_id:       Dentist.all.sample.id,
        appointment_type_id: appt_type.id,
        appointment_time: apt_time,
        status:           apt_status,
        notes:            Faker::Lorem.sentence(word_count: 6)
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "  -> Skipping invalid appointment: #{e.message}"
      # That’s all—this prevents seeds from crashing.
    end
  end
end

puts "Seeding complete!"
puts "--------------------------------------------------"
puts "Summary:"
puts " - Dentists: #{Dentist.count}"
puts " - Admin Users: #{User.where(role: 'admin').count}"
puts " - Phone-Only Users: #{User.where(role: 'phone_only', is_dependent: false).count}"
puts " - Regular Users (non-dependent): #{User.where(role: 'user', is_dependent: false).count}"
puts " - Child (dependent) Users: #{User.where(is_dependent: true).count}"
puts " - AppointmentTypes: #{AppointmentType.count}"
puts " - Appointments: #{Appointment.count}"
puts " - DentistUnavailabilities: #{DentistUnavailability.count}"
puts " - Specialties: #{Specialty.count}"
puts " - ClosedDays: #{ClosedDay.count}"
