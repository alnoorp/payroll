require 'csv'

class Float
  def floor_to(x)
    sprintf('%.2f', (self * 10**x).floor.to_f / 10**x)
  end
end

class Employee
  attr_reader :name, :base_salary
  def initialize(name, base_salary)
    @name = name
    @base_salary = base_salary
  end

  def gross_salary(filename)
    (@base_salary / 12)
  end

  def net_pay(filename)
    gross_salary(filename) * ( 1 - Employee.tax_rate )
  end

  class << self
    def tax_rate
      0.3
    end

    def list_employees(filename)
      EmployeeReader.new(filename).list.each do |employee|
        puts employee.name
      end
    end
  end
end

class Owner < Employee

  def initialize(name, base_salary, quota, bonus)
    super(name, base_salary)
    @quota = quota
    @bonus = bonus
  end

  def gross_salary(filename)
    if exceed_quota?(filename)
      (@base_salary / 12 + @bonus)
    else
      (@base_salary / 12)
    end
  end

  def net_pay(filename)
    gross_salary(filename) * ( 1 - Employee.tax_rate )
  end

  private

  def exceed_quota?(filename)
    @gross_sales = 0
    Sale.sales_list(filename).each do |person|
      @gross_sales += person.gross_sale_value
    end
    @gross_sales >= @quota
  end
end

class CommissionSalesPerson < Employee

  def initialize(name, base_salary, commission)
    super(name, base_salary)
    @commission = commission
  end

  def commission(filename)
    gross_sales = 0
    Sale.sales_list(filename).each do |person|
      if self.name.include?(person.last_name)
        gross_sales += person.gross_sale_value
      end
    end
    gross_sales * @commission
  end

  def gross_salary(filename)
    (@base_salary / 12)
  end

  def net_pay(filename)
    (gross_salary(filename) + commission(filename)) * ( 1 - Employee.tax_rate )
  end

end

class QuotaSalesPerson < Employee
  attr_reader :quota, :bonus
  def initialize(name, base_salary, quota, bonus)
    super(name, base_salary)
    @quota = quota
    @bonus = bonus
  end

  def gross_salary(filename)
    if exceed_quota?(filename)
      (@base_salary / 12 + bonus)
    else
      (@base_salary / 12)
    end
  end

  def net_pay(filename)
    gross_salary(filename) * ( 1 - Employee.tax_rate )
  end

  private

  def exceed_quota?(filename)
    @gross_sales = 0
    Sale.sales_list(filename).each do |person|
      if self.name.include?(person.last_name)
        @gross_sales += person.gross_sale_value
      end
    end
    @gross_sales >= @quota
  end
end

class Sale
  attr_reader :last_name, :gross_sale_value
  def initialize(last_name, gross_sale_value)
    @last_name = last_name
    @gross_sale_value = gross_sale_value
  end

  def self.sales_list(filename)
    @sales_array = []
    CSV.foreach(filename, headers: true) do |row|
      @sales_array << Sale.new(row['last_name'], row['gross_sale_value'].to_f)
    end
    @sales_array
  end
end

class EmployeeReader

  def initialize(filename)
    @employees = []
    CSV.foreach(filename, headers: true) do |row|
      if row['Type'] == 'Commission'
        @employees << CommissionSalesPerson.new(row['Name'], row['Base Salary'].to_f, row['Commission'].to_f)
      elsif row['Type'] == 'Quota'
        @employees << QuotaSalesPerson.new(row['Name'], row['Base Salary'].to_f, row['Quota'].to_f, row['Bonus'].to_f)
      elsif row['Type'] == 'Owner'
        @employees << Owner.new(row['Name'], row['Base Salary'].to_f, row['Quota'].to_f, row['Bonus'].to_f)
      else
        @employees << Employee.new(row['Name'], row['Base Salary'].to_f)
      end
    end
    @employees
  end

  def list
    @employees
  end
end

filename = 'employee_data.csv'
employees = EmployeeReader.new(filename)

Employee.list_employees(filename) # list of employees

sales_file = 'sales.csv'

employees.list.each do |person|
  puts "***#{person.name}***"
  puts "Gross Salary: $#{person.gross_salary(sales_file).floor_to(2)}"
  puts "Commission: $#{person.commission(sales_file).floor_to(2)}" if person.methods.include?(:commission)
  puts "Net Pay: $#{person.net_pay(sales_file).floor_to(2)}"
  puts "***"
  puts
end
