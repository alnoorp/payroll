require 'csv'

class Float
  def floor_to(x)
    sprintf('%.2f', (self * 10**x).floor.to_f / 10**x)
  end
end

class Employee
  @@all_employees = []
  attr_reader :name, :base_salary

  def initialize(data = {})
    @name = data['Name']
    @base_salary = data['Base Salary'].to_f
    @sales = []
  end

  def monthly_salary
    @base_salary / 12
  end

  def gross_salary
    monthly_salary
  end

  def net_pay
    gross_salary * ( 1 - Employee.tax_rate )
  end

  def add_sale(sale)
    @sales << sale
  end

  def total_sales
    @total = 0
    @sales.each do |sale|
      @total += sale.gross_sale_value
    end
    @total
  end

  class << self
    def tax_rate
      0.3
    end

    def all_employees
      @@all_employees
    end

    def employee_named(name)
      @@all_employees.find{|employee| employee.name.include?(name) }
    end

    def load_employees(filename)
      CSV.foreach(filename, headers: true) do |row|
        data = row.to_hash
        if row['Type'] == 'Commission'
          @@all_employees << CommissionSalesPerson.new(data)
        elsif row['Type'] == 'Quota'
          @@all_employees << QuotaSalesPerson.new(data)
        elsif row['Type'] == 'Owner'
          @@all_employees << Owner.new(data)
        else
          @@all_employees << Employee.new(data)
        end
      end
      @@all_employees
    end
  end
end

class Owner < Employee

  def initialize(data = {})
    super(data)
    @quota = data['Quota'].to_f
    @bonus = data['Bonus'].to_f
  end

  def gross_salary
    if exceed_quota?
      monthly_salary + @bonus
    else
      monthly_salary
    end
  end

  def net_pay
    gross_salary * ( 1 - Employee.tax_rate )
  end

  private

  def exceed_quota?
    grand_total_sales = 0
    @@all_employees.each do |employee|
      grand_total_sales += employee.total_sales
    end
    grand_total_sales > @quota
  end
end

class CommissionSalesPerson < Employee

  def initialize(data = {})
    super(data)
    @commission = data['Commission'].to_f
  end

  def commission
    total_sales * @commission
  end

  def gross_salary
    monthly_salary
  end

  def net_pay
    (gross_salary + commission) * ( 1 - Employee.tax_rate )
  end

end

class QuotaSalesPerson < Employee
  attr_reader :quota, :bonus
  def initialize(data = {})
    super(data)
    @quota = data['Quota'].to_f
    @bonus = data['Bonus'].to_f
  end

  def gross_salary
    if exceed_quota?
      monthly_salary + @bonus
    else
      monthly_salary
    end
  end

  def net_pay
    gross_salary * ( 1 - Employee.tax_rate )
  end

  private

  def exceed_quota?
    total_sales > @quota
  end
end

class Sale
  attr_reader :last_name, :gross_sale_value
  def initialize(data)
    @last_name = data['last_name']
    @gross_sale_value = data['gross_sale_value'].to_f
  end

  def self.sales_list(filename)
    @sales_array = []
    CSV.foreach(filename, headers: true) do |row|
      data = row.to_hash
      sale = Sale.new(data)
      @sales_array << sale
      found_employee = Employee.employee_named(row['last_name'])
      found_employee.add_sale(sale)
    end
    @sales_array
  end
end

filename = 'employee_data.csv'
employees = Employee.load_employees(filename)
sales_file = 'sales.csv'
all_sales = Sale.sales_list(sales_file)

# binding.pry
employees.each do |person|
  puts "***#{person.name}***"
  puts "Gross Salary: $#{person.gross_salary.floor_to(2)}"
  puts "Commission: $#{person.commission.floor_to(2)}" if person.methods.include?(:commission)
  puts "Net Pay: $#{person.net_pay.floor_to(2)}"
  puts "***"
  puts
end
