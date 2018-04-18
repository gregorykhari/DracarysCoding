require 'sqlite3'
require 'csv'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/flash'


#debug includes'
require 'logger'
Dir.mkdir('logs') unless File.exist?('logs')
$log = Logger.new('logs/output.log','weekly')


#configure debug log on development
configure :development do
  $log.level = Logger::DEBUG
end


configure do
	enable :sessions
	set :root, File.dirname(__FILE__)
	set :view, Proc.new { File.join(root,"views") }
	set :adminUsername, 'admin'
	set :adminPassword, 'admin'
end

#set database name
DBName = "DragonairBreeders.sqlite"

#connect to database
DB = SQLite3::Database.new(DBName)

#function to create table to hold dragon information
def createDragonsTable()
	DB.execute("CREATE TABLE dragons(dragonID Integer PRIMARY KEY, dragonName String, age Integer, gender String, colour String, parentName String, type String, species String, region String, foodPreference String, caretakerID Integer, adopted Integer)")
end

#function to create table to hold employee information
def createEmployeeTable()
	DB.execute("CREATE TABLE employees(employeeID Integer PRIMARY KEY, firstName String, lastName Sting, gender String, dateOfBirth String, role String, weeklyHours Integer, salary Real, phoneNumber String, emailAddress String, loginPassword String)")
end

#function to create table to hold IDs of dragons which were adopted
def createAdoptionTable()
	DB.execute("CREATE TABLE adoptions(adopterID Integer PRIMARY KEY, adopterFirstName String, adopterLastName String, adopterAge Integer, adopterGender String, adopterPhoneNumber String, adopterAddress String, adopterCity String, adopterState String, adopterHomeType String, reasonForAdopting String, dragonID Integer, dragonName String, dateOfAdoption String)")
end

#function to add new dragon to database
def addNewDragon(dragonID, dragonName, age, gender, colour, parentName, type, species, region, foodPreference,caretakerID)

	#query to insert new dragon into dragon table
	insertQuery = "INSERT INTO dragons(dragonID, dragonName, age, gender, colour, parentName, type, species, region, foodPreference, caretakerID, adopted) VALUES ('#{dragonID}', '#{dragonName}', '#{age}', '#{gender}', '#{colour}', '#{parentName}', '#{type}', '#{species}', '#{region}', '#{foodPreference}','#{caretakerID}','0')"
	DB.execute(insertQuery)

	return true
end

#function to release dragon from care (delete from database)
def releaseDragon(dragonID,caretakerID)

	#query to release dragon from care
	deleteQuery = "DELETE FROM dragons WHERE dragonID = #{dragonID} AND caretakerID = #{caretakerID}"
	DB.execute(deleteQuery)

	return true
end #end releaseDragons

#function to search database for dragon with specific characteristics
def searchDragons(field, comparison, value)

	#query to return all information about 
	searchQuery = "SELECT * FROM dragons WHERE #{field} #{comparison} '#{value}'"
	result = DB.execute(searchQuery)

	#return false if dragon does not exist
	if result == []
		return nil
	else
		#return result if dragon exists
		return result
	end
end #end searchDragons

#function to add new employee to 
def addNewEmployee(employeeID, firstName, lastName, gender, dateOfBirth, role, weeklyHours, salary, phoneNumber, emailAddress, loginPassword)
	
	#query to insert new employee into database 
	insertQuery = "INSERT INTO employees(employeeID, firstName, lastName, gender, dateOfBirth, role, weeklyHours, salary, phoneNumber, emailAddress, loginPassword) VALUES ('#{employeeID}', '#{firstName}', '#{lastName}', '#{gender}', '#{role}', '#{dateOfBirth}', '#{weeklyHours}', '#{salary}', '#{phoneNumber}', '#{emailAddress}', '#{loginPassword}')"
	DB.execute(insertQuery)

	return true
end #end 

#function to delete employee from database
def deleteEmployee(employeeID, lastName)

	#query to delete employee from database 
	deleteQuery = "DELETE FROM employees WHERE employeeID = '#{employeeID}' AND lastName = '#{lastName}'"
	DB.execute(deleteQuery)

	return true
end #end deleteEmployee

#function to search database for employee
def searchEmployees(field, comparison, value)

	#query to return all information about 
	searchQuery = "SELECT employeeID, firstName, lastName, gender, dateOfBirth, role, phoneNumber, emailAddress FROM employees WHERE #{field} #{comparison} '#{value}'"
	result = DB.execute(searchQuery)

	#return false if employees does not exist
	if result == []
		return nil
	else
		#return result if employee exists
		return result
	end
end #end searchEmployees

#function to update adoption table to show dragon was adopted
def adoptDragon(adopterID,adopterFirstName,adopterLastName,adopterAge,adopterGender,adopterPhoneNumber,adopterAddress,adopterCity,adopterState,adopterHomeType,reasonForAdopting,dragonID,dragonName,dateOfAdoption)
	insertQuery = "INSERT INTO adoptions(adopterID,adopterFirstName,adopterLastName,adopterAge,adopterGender,adopterPhoneNumber,adopterAddress,adopterCity,adopterState,adopterHomeType,reasonForAdopting,dragonID,dragonName,dateOfAdoption) VALUES('#{adopterID}','#{adopterFirstName}','#{adopterLastName}','#{adopterAge}','#{adopterGender}','#{adopterPhoneNumber}','#{adopterAddress}','#{adopterCity}','#{adopterState}','#{adopterHomeType}','#{reasonForAdopting}','#{dragonID}','#{dragonName}','#{dateOfAdoption}')"
	DB.execute(insertQuery)
	updateQuery = "UPDATE dragons SET adopted=1 WHERE dragonID=#{dragonID} AND dragonName='#{dragonName}'"
	DB.execute(updateQuery)
end

#function to verify employee login
def verifyLogin(employeeID,password)

	verifyQuery = "SELECT loginPassword FROM employees WHERE employeeID='#{employeeID}' AND loginPassword='#{password}'"
	result = DB.execute(verifyQuery)

	#return false if employees does not exist
	if result == []
		return false
	else
		#return result if employee exists
		return true
	end
end 

def exportDragonReportCSV(field, comparison, value)

	File.delete("DragonReport.csv") if File.exists? "DragonReport.csv"
  
  	record = {:dragonID=>"Dragon ID",:dragonName=>"Dragon Name",:age=>"Age",:gender=>"Gender",:colour=>"Colour",:parentName=>"Parent's Name",:type=>"Type",:species=>"Species",:region=>"Region",:foodPreference=>"Food Preference",:caretakerID=>"Caretaker ID",:adopted=>"Adoption Status"}
    CSV.open("DragonReport.csv", "w") do |csv|
        csv << record.values
        csv.close()
    end
    
  	#get result from select_query
  	results = searchDragons(field, comparison, value)

    results.each do |row|
      	row = row.to_s
      	row = row.gsub("[","").gsub("\"","").gsub(",","").gsub("\\n","").gsub("]","")

      	dragonID, dragonName, age, gender, colour, parentName, type, species, region, foodPreference, caretakerID, adopted = row.split(" ")
      	record = {:dragonID=>"#{dragonID}",:dragonName=>"#{dragonName}",:age=>"#{age}",:gender=>"#{gender}",:colour=>"#{colour}",:parentName=>"#{parentName}",:type=>"#{type}",:species=>"#{species}",:region=>"#{region}",:foodPreference=>"#{foodPreference}",:caretakerID=>"#{caretakerID}",:adopted=>"#{adopted}"}
      	CSV.open("DragonReport.csv", "a+") do |csv|
        	csv << record.values
        	csv.close()
    	end
    end
end

#exports CSV file to report.csv
def exportEmployeesReportCSV(field, comparison, value)


	File.delete("EmployeesReport.csv") if File.exists? "EmployeesReport.csv"
  
	record = {:employeeID=>"employeeID",:firstName=>"First Name",:lastName=>"Last Name",:gender=>"Gender",:dateOfBirth=>"Date Of Birth",:role=>"Role",:phoneNumber=>"Phone Number",:emailAddress=>"Email Address"}
	CSV.open("EmployeesReport.csv", "w") do |csv|
    	csv << record.values
        csv.close()
    end

 	#get result from select_query
  	results = searchEmployees(field, comparison, value)
  
    results.each do |row|
      	row = row.to_s
      	row = row.gsub("[","").gsub("\"","").gsub(",","").gsub("\\n","").gsub("]","")

      	employeeID, firstName, lastName, gender, dateOfBirth, role, phoneNumber, emailAddress  = row.split(" ")
      	record = {:employeeID=>"#{employeeID}",:firstName=>"#{firstName}",:lastName=>"#{lastName}",:gender=>"#{gender}",:dateOfBirth=>"#{dateOfBirth}",:role=>"#{role}",:weeklyHours=>"#{weeklyHours}",:salary=>"#{salary}",:phoneNumber=>"#{phoneNumber}",:emailAddress=>"#{emailAddress}",:loginPassword=>"#{loginPassword}"}
      
      	CSV.open("EmployeesReport.csv", "a+") do |csv|
        	csv << record.values
        	csv.close()
    	end
    end
end

get '/' do
	erb :loginPage
end 

get '/login' do
	erb :loginPage
end 

post '/login' do

	employeeID = params[:employeeID].to_s
	loginPassword = params[:loginPassword].to_s 

	if employeeID == settings.adminUsername and loginPassword == settings.adminPassword
		redirect to('/admin')
	end

	valid = verifyLogin(employeeID,loginPassword)

	if valid == true
		redirect to('/admin')
	else
		flash[:notice] = "INVALID EMPLOYEE ID OR PASSWORD"
		redirect to('/login')
	end
end

get '/admin' do
	erb :adminPage
end

get '/addDragon' do
	erb :addDragon
end

#handles insertion of dragon into system
post '/addDragon' do

	dragonID = params[:dragonID].to_i
	dragonName = params[:dragonName].to_s.capitalize
	age = params[:age].to_i
	gender = params[:gender].to_s.capitalize 
	colour = params[:colour].to_s.capitalize 
	parentName = params[:parentName].to_s.capitalize
	type = params[:type].to_s.capitalize
	species = params[:species].to_s.capitalize
	region = params[:region].to_s.capitalize
	foodPreference = params[:foodPreference].to_s.capitalize
	caretakerID = params[:caretakerID].to_i

	success = addNewDragon(dragonID,dragonName,age,gender,colour,parentName,type,species,region,foodPreference,caretakerID)

	redirect to('/admin')
end

get '/releaseDragon' do
	erb :releaseDragon
end

#handles removal of dragon from system
post '/releaseDragon' do

	dragonID = params[:dragonID].to_i
	caretakerID = params[:caretakerID].to_i
	adminPassword = params[:adminPassword].to_s

	success = releaseDragon(dragonID,caretakerID)

	redirect to('/admin')
end 

get '/addEmployee' do
	erb :addEmployee
end

#handles insertion of employee into system
post '/addEmployee' do

	employeeID = params[:employeeID].to_i
	firstName = params[:firstName].to_s.capitalize
	lastName = params[:lastName].to_s.capitalize
	gender = params[:gender].to_s.capitalize
	dateOfBirth = params[:dateOfBirth].to_s 
	role = params[:role].to_s.capitalize
	weeklyHours = params[:weeklyHours].to_i
	salary = params[:salary].to_i
	phoneNumber = params[:phoneNumber].to_s
	emailAddress = params[:emailAddress].to_s
	loginPassword = params[:password].to_s

	success = addNewEmployee(employeeID,firstName,lastName,gender,dateOfBirth,role,weeklyHours,salary,phoneNumber,emailAddress,loginPassword)

	redirect to('/admin')
end

get '/deleteEmployee' do
	erb :deleteEmployee
end

#handles deletion of employee from system
#requires admin password to execute
post '/deleteEmployee' do

	employeeID = params[:employeeID].to_i
	lastName = params[:lastName].to_s.capitalize
	adminPassword = params[:adminPassword].to_s

	if settings.adminPassword == adminPassword
		success = deleteEmployee(employeeID, lastName)
	else 
		flash[:notice] = "INVALID ADMIN PASSWORD ENTERED"
		redirect to('/deleteEmployee')
	end

	redirect to('/admin')
end

get '/viewAvailableDragons' do
	results = searchDragons("adopted","=",0)
	erb :viewAvailableDragons, :locals => {:results => results}
end

get '/adoptDragon' do
	erb :adoptDragon
end

post '/adoptDragon' do

	adopterID = params[:adopterID].to_i
	adopterFirstName = params[:adopterFirstName].to_s.capitalize
	adopterLastName = params[:adopterLastName].to_s.capitalize
	adopterAge = params[:adopterAge].to_i
	adopterGender = params[:adopterGender].to_s.capitalize
	adopterPhoneNumber = params[:adopterPhoneNumber].to_s
	adopterAddress = params[:adopterAddress].to_s.capitalize
	adopterCity = params[:adopterCity].to_s.capitalize
	adopterState = params[:adopterState].to_s.capitalize
	adopterHomeType = params[:adopterHomeType].to_s.capitalize
	reasonForAdopting = params[:reasonForAdopting].to_s.capitalize
	dragonID = params[:dragonID].to_i
	dragonName = params[:dragonName].to_s.capitalize
	dateOfAdoption = params[:dateOfAdoption].to_s

	if not searchDragons("dragonID","=",dragonID) or not searchDragons("dragonName","=",dragonName)
		flash[:notice] = "DRAGON #{dragonName} WITH DRAGON ID #{dragonID} NOT PRESENT IN SYSTEM"
		redirect to('/adoptDragon')
	else
		success = adoptDragon(adopterID,adopterFirstName,adopterLastName,adopterAge,adopterGender,adopterPhoneNumber,adopterAddress,adopterCity,adopterState,adopterHomeType,reasonForAdopting,dragonID,dragonName,dateOfAdoption)
		redirect to('/admin')
	end
end

get '/dragonReports' do
	results = searchDragons("dragonID",">",0)
	erb :dragonReports, :locals => {:results => results}
end

post '/dragonReports' do

	searchField = params[:searchField].to_s
	comparisonOp = params[:comparisonOp].to_s
	searchValue = params[:searchValue].to_s.capitalize
	if searchField == "" or comparisonOp == "" or searchValue == ""
		redirect to('/dragonReports')
	end

	results = searchDragons(searchField,comparisonOp,searchValue)
	erb :dragonReports, :locals => {:results => results}

end

get '/employeeReports' do
	results = searchEmployees("employeeID",">",0)
	erb :employeeReports, :locals => {:results => results}
end

post '/employeeReports' do
	searchField = params[:searchField].to_s
	comparisonOp = params[:comparisonOp].to_s
	searchValue = params[:searchValue].to_s.capitalize
	if searchField == "" or comparisonOp == "" or searchValue == ""
		redirect to('/employeeReports')
	end

	results = searchEmployees(searchField,comparisonOp,searchValue)
	erb :employeeReports, :locals => {:results => results}
end

post '/exportDragonReport' do

	exportDragonReportCSV("dragonID",">",0)

	redirect to('/dragonReports')
end

post '/exportEmployeeReport' do

	exportEmployeesReportCSV("employeeID",">",0)

	redirect to('/employeeReports')
end