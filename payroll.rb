require 'csv'
require 'pry'

class Employee
  attr_reader :name, :base_salary
  def initialize(name, base_salary)
    @name = name
    @base_salary = base_salary
  end

  def gross_salary
  end

  def net_pay
  end

  def self.list_employees(filename)
    # return a list of employees loaded from a CSV
    @employees = []
    CSV.foreach(filename, headers: true) do |row|
      @employees << { name: row['Name'], base_salary: row['Base Salary'] }
    end
    @employees.each do |employee|
      puts "#{employee[:name]}, #{employee[:base_salary]}"
    end
  end
end

class Owner < Employee

  def net_pay
  end
end

class CommissionSalesPerson < Employee

  def net_pay
  end
end

class QuotaSalesPerson < Employee

  def net_pay
  end
end

class Sale
end


class EmployeeReader

  def initialize(filename)
    @employees = []
    CSV.foreach(filename, headers: true) do |row|
      @employees << { name: row['Name'], base_salary: row['Base Salary'] }
    end
  end
end

filename = 'employee_data.csv'
employees = EmployeeReader.new(filename)

Employee.list_employees(filename)

# binding.pry
