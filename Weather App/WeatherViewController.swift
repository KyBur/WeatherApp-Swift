//
//  WeatherViewController.swift
//  Weather App
//
//  Created by Kyle Burns on 4/9/20.
//  Copyright © 2020 Kyle Burns. All rights reserved.
//

import UIKit
import AlamofireImage

class WeatherViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var weatherTableView: UITableView!
    
    var weatherData = [[String:Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cityNameLabel.text = ""
        weatherTableView.delegate = self
        weatherTableView.dataSource = self
        
    }
    
    @IBAction func onSubmit(_ sender: Any) {
        let city = cityTextField.text!
        if(city.isEmpty){
            self.alertView(error: "Enter a city")
        }
        //For cities with multiword names, replace space with '_'
        let urlCity = city.replacingOccurrences(of: " ", with: "_")
        cityTextField.text = ""
        cityTextField.resignFirstResponder()
        
        //weatherbit documentation: https://www.weatherbit.io/api/weather-forecast-16-day
        //weatherbit API Key
        let apiKey = "176c9480c3dc481ab292654658b4f88355"
        //Construct API url with catch for invalid input
        if let url = URL(string: "https://api.weatherbit.io/v2.0/forecast/daily?city=\(urlCity)&key=\(apiKey)") {
            //API Call
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
            let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request) { (data, response, error) in
                //This will run when the network request returns
                if let error = error {
                    print(error.localizedDescription)
                } else if let data = data {
                    do {
                        let dataDictionary = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                        //Grabs data array from API if it is valid, otherwise displays an error popup
                        guard let APIdata = dataDictionary["data"] else {
                            if let errorResults = dataDictionary["error"] as? String {
                                self.alertView(error: "Error: \(errorResults)")
                            }
                            print("API data not found (city field left blank)")
                            return
                        }
                        self.weatherData = APIdata as! [[String:Any]]
                        //Pulls first 10 days from array not including current day(Project requirement)
                        self.weatherData = Array(self.weatherData[1...10])
                        self.cityNameLabel.text = city
                        
                        self.weatherTableView.reloadData()
                    }
                        
                    catch (_) {
                        //City name is not valid/has no data from API
                        self.alertView(error: "Please enter a valid city")
                        print("Invalid City Name")
                    }
                }
            }
            task.resume()
        }
        else{
            //Case where URL contains invalid items such as emojis
            alertView(error: "Please enter valid characters for city")
            print("Invalid URL")
        }
        
        
    }
    func alertView(error: String){
        //Creates and displays error message for incorrect input
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return weatherData.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = weatherTableView.dequeueReusableCell(withIdentifier: "WeatherTableViewCell", for: indexPath) as! WeatherTableViewCell
        
        let day = weatherData[indexPath.row]
        
        let weather = day["weather"] as! NSDictionary
        let desc = weather["description"] as! String
        let iconID = weather["icon"] as! String
        
        let tempCelsius = day["temp"] as! NSNumber
        //Converts temperature to fahrenheit, rounds it, and then represents it as an Int to remove decimal
        let tempFahrenheit = Int(((tempCelsius.doubleValue * 1.8) + 32).rounded())
        
        let weekDate = day["datetime"] as! String
        
        let weekDays = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        
        cell.weatherLabel?.text = desc
        cell.tempLabel?.text = "\(tempFahrenheit)°"
        if let weekDayNumber = getDayOfWeek(weekDate) {
            
            //weekDays[weekDayNumber-1] is current weekday name, ex: Tuesday
            //weekDate.suffix(5) is number date, ex: 04-10
            cell.dayLabel?.text = "\(weekDays[weekDayNumber-1]) \(weekDate.suffix(5))"
        } else {
            print("Incorrect date information")
        }
        //Uses AlamoFireImage to display weather image from API
        let imgURL = URL(string: "https://weatherbit.io/static/img/icons/\(iconID).png")
        cell.weatherImageView.af_setImage(withURL: imgURL!)

        
        return cell
    }
    //Gets number of day in week
    func getDayOfWeek(_ day:String) -> Int? {
        let formatter  = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let todayDate = formatter.date(from: day) else { return nil }
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: todayDate)
        return weekDay
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
