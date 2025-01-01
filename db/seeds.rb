# db/seeds.rb

puts "Cleaning existing records..."
Appointment.destroy_all
AppointmentType.destroy_all
DentistAvailability.destroy_all
Dentist.destroy_all
Dependent.destroy_all
User.destroy_all

puts "Creating Users..."
admin_user = User.create!(
  email: "admin@example.com",
  password: "password",
  role: "admin",
  provider_name: "Delta Dental",
  policy_number: "AAA111",
  plan_type: "PPO",
  phone: "555-0001",
  first_name: "Admin",
  last_name: "User"
)

parent_user = User.create!(
  email: "parent@example.com",
  password: "password",
  role: "user",
  provider_name: "Guardian",
  policy_number: "BBB222",
  plan_type: "HMO",
  phone: "555-0002",
  first_name: "John",
  last_name: "Parent"
)

puts "Creating Dependents..."
child_dependent = parent_user.dependents.create!(
  first_name: "Sally",
  last_name: "Child",
  date_of_birth: "2012-05-01"
)

parent_dependent = parent_user.dependents.create!(
  first_name: "ParentAsDependent",
  last_name: "Example",
  date_of_birth: "1980-01-01"
)

puts "Creating Dentists..."
dentist_adult = Dentist.create!(
  first_name: "Jane",
  last_name: "Doe",
  specialty: "Adult Dentistry"
)

dentist_pediatric = Dentist.create!(
  first_name: "Joe",
  last_name: "Kiddo",
  specialty: "Pediatric Dentistry"
)

puts "Creating Appointment Types..."
cleaning_type = AppointmentType.create!(
  name: "Cleaning",
  description: "Routine cleaning"
)

filling_type = AppointmentType.create!(
  name: "Filling",
  description: "Cavity filling"
)

checkup_type = AppointmentType.create!(
  name: "Checkup",
  description: "General checkup"
)

puts "Creating Appointments..."
Appointment.create!(
  user: parent_user,
  dependent: child_dependent,
  dentist: dentist_adult,
  appointment_type: cleaning_type,
  appointment_time: Time.current + 1.week,
  status: "scheduled"
)

Appointment.create!(
  user: parent_user,
  dependent: parent_dependent,
  dentist: dentist_pediatric,
  appointment_type: checkup_type,
  appointment_time: Time.current + 2.weeks,
  status: "scheduled"
)

puts "Creating Dentist Availabilities..."
DentistAvailability.create!(dentist: dentist_adult,    day_of_week: 1, start_time: "09:00", end_time: "17:00")
DentistAvailability.create!(dentist: dentist_adult,    day_of_week: 2, start_time: "09:00", end_time: "17:00")
DentistAvailability.create!(dentist: dentist_adult,    day_of_week: 3, start_time: "09:00", end_time: "17:00")
DentistAvailability.create!(dentist: dentist_adult,    day_of_week: 4, start_time: "09:00", end_time: "17:00")
DentistAvailability.create!(dentist: dentist_adult,    day_of_week: 5, start_time: "09:00", end_time: "15:00")

DentistAvailability.create!(dentist: dentist_pediatric, day_of_week: 1, start_time: "10:00", end_time: "18:00")
DentistAvailability.create!(dentist: dentist_pediatric, day_of_week: 2, start_time: "10:00", end_time: "18:00")
DentistAvailability.create!(dentist: dentist_pediatric, day_of_week: 4, start_time: "10:00", end_time: "18:00")
DentistAvailability.create!(dentist: dentist_pediatric, day_of_week: 5, start_time: "10:00", end_time: "16:00")

puts "Seeding complete!"
puts "Created:"
puts " - 1 Admin User (admin@example.com / password)"
puts " - 1 Regular User (parent@example.com / password) with 2 dependents"
puts " - 2 Dentists (Adult / Pediatric)"
puts " - 3 Appointment Types (Cleaning, Filling, Checkup)"
puts " - 2 Appointments"
puts " - DentistAvailability (Schedules) for each dentist"
