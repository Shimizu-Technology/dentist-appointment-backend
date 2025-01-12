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
# 6) CREATE CHILD USERS (DEPENDENTS)
#    We skip email/password for them. They are typically phone_only.
#    We’ll do so for both 'user' and 'admin' (some admins might have dependents).
# -------------------------------------------------------------------
puts "Creating child (dependent) users for each non-dependent user (role='user' or 'admin')..."

eligible_parents = User.where(is_dependent: false).where(role: %w[user admin])
eligible_parents.each do |parent|
  # Randomly create 0..3 dependents
  rand(0..3).times do
    User.create!(
      is_dependent:    true,
      parent_user_id:  parent.id,
      role:            'phone_only',  # ensures no email/password validations
      phone:           nil,           # child uses parent's phone
      email:           nil,           # child uses parent's email
      first_name:      Faker::Name.first_name,
      last_name:       parent.last_name,  # match parent's last name
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

def random_appointment_time
  max_tries = 365
  tries     = 0
  in_future = [true, false].sample
  offset_days = rand(1..90)
  base_date = in_future ? Date.current + offset_days : Date.current - offset_days

  loop do
    tries += 1
    raise "Cannot find a valid open day/time after #{max_tries} tries." if tries > max_tries

    if ClosedDay.exists?(date: base_date)
      base_date = in_future ? base_date + 1.day : base_date - 1.day
      next
    end

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

    base_date = in_future ? base_date + 1.day : base_date - 1.day
  end
end

all_regular_or_admin_parents = User.where(is_dependent: false).where(role: %w[user admin])

all_regular_or_admin_parents.each do |parent|
  # child users for this parent
  child_users_for_this_parent = User.where(parent_user_id: parent.id, is_dependent: true)

  # Create between 1..5 appointments (some in future, some in past)
  rand(1..5).times do
    apt_time   = random_appointment_time
    is_future  = apt_time >= Time.current
    apt_status = is_future ? FUTURE_STATUSES.sample : PAST_STATUSES.sample
    appt_type  = AppointmentType.all.sample

    # Possibly schedule for the child
    chosen_child = (child_users_for_this_parent.any? && rand(2).zero?) ? child_users_for_this_parent.sample : nil

    begin
      Appointment.create!(
        user_id:          chosen_child&.id || parent.id,
        dentist_id:       Dentist.all.sample.id,
        appointment_type_id: appt_type.id,
        appointment_time: apt_time,
        status:           apt_status,
        notes:            Faker::Lorem.sentence(word_count: 6)
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "  -> Skipping invalid appointment: #{e.message}"
    end
  end
end

puts "Seeding complete!"
puts "--------------------------------------------------"
puts "Summary:"
puts " - Dentists:                #{Dentist.count}"
puts " - Admin Users:             #{User.where(role: 'admin').count}"
puts " - Phone-Only Users:        #{User.where(role: 'phone_only', is_dependent: false).count}"
puts " - Regular (non-dependent): #{User.where(role: 'user', is_dependent: false).count}"
puts " - Child (dependent) Users: #{User.where(is_dependent: true).count}"
puts " - AppointmentTypes:        #{AppointmentType.count}"
puts " - Appointments:            #{Appointment.count}"
puts " - DentistUnavailabilities: #{DentistUnavailability.count}"
puts " - Specialties:             #{Specialty.count}"
puts " - ClosedDays:              #{ClosedDay.count}"
