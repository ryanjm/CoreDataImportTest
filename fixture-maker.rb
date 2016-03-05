require 'faker'
require 'json'

# Create file with 10 businesses
# Create file with 1,000 employees, 100 at each company

num_companies = 30
num_employees_at_each = 100

companies = []
employees = []
employee_id = 1

num_companies.times do |i|
  companies << {
    name: Faker::Company.name,
    id: i + 1
  }

  num_employees_at_each.times do |j|
    employees << {
      name: Faker::Name.name,
      id: employee_id,
      companyId: i
    }
    employee_id += 1
  end
end

File.open("./CoreDataImportTest/Fixtures/companies.json", "w") do |f|
  f.puts JSON.generate(companies)
end

File.open("./CoreDataImportTest/Fixtures/employees.json", "w") do |f|
  f.puts JSON.generate(employees)
end
