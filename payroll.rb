require 'csv'
require 'pry'

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

    def all_employees
      @all_employees
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

  def initialize(data = {})
    super(data)
    @commission = data['Commission'].to_f
  end

  def my_sales(filename)
    @my_sales = []
    Sale.sales_list(filename).each do |row|
      if self.name.include?(row.last_name)
        @my_sales << row.gross_sale_value
      end
    end
    @my_sales
  end

  def commission(filename)
    my_sales(filename).inject(:+) * @commission
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
  def initialize(data = {})
    super(data)
    @quota = data['Quota'].to_f
    @bonus = data['Bonus'].to_f
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

filename = 'employee_data.csv'
employees = Employee.load_employees(filename)

sales_file = 'sales.csv'
# binding.pry
employees.each do |person|
  puts "***#{person.name}***"
  puts "Gross Salary: $#{person.gross_salary(sales_file).floor_to(2)}"
  puts "Commission: $#{person.commission(sales_file).floor_to(2)}" if person.methods.include?(:commission)
  puts "Net Pay: $#{person.net_pay(sales_file).floor_to(2)}"
  puts "***"
  puts
end

binding.pry
