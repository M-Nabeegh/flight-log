// Builds the sample flight log that ships with the public repo.
// Invented data — no relation to any real person's travel.
const fs = require('fs');

const AP = [
  ['LHR','London','Heathrow','United Kingdom',51.4700,-0.4543],
  ['EDI','Edinburgh','Edinburgh Airport','United Kingdom',55.9500,-3.3725],
  ['CDG','Paris','Charles de Gaulle','France',49.0097,2.5479],
  ['AMS','Amsterdam','Schiphol','Netherlands',52.3105,4.7683],
  ['FRA','Frankfurt','Frankfurt Airport','Germany',50.0379,8.5622],
  ['BCN','Barcelona','El Prat','Spain',41.2974,2.0833],
  ['FCO','Rome','Fiumicino','Italy',41.8003,12.2389],
  ['LIS','Lisbon','Humberto Delgado','Portugal',38.7742,-9.1342],
  ['ZRH','Zurich','Zurich Airport','Switzerland',47.4647,8.5492],
  ['KEF','Reykjavik','Keflavik','Iceland',63.9850,-22.6056],
  ['DUB','Dublin','Dublin Airport','Ireland',53.4213,-6.2701],
  ['ATH','Athens','Eleftherios Venizelos','Greece',37.9364,23.9445],
  ['IST','Istanbul','Istanbul Airport','Türkiye',41.2753,28.7519],
  ['DXB','Dubai','Dubai Intl','UAE',25.2532,55.3657],
  ['DOH','Doha','Hamad Intl','Qatar',25.2731,51.6081],
  ['DEL','Delhi','Indira Gandhi Intl','India',28.5562,77.1000],
  ['BOM','Mumbai','Chhatrapati Shivaji','India',19.0896,72.8656],
  ['SIN','Singapore','Changi','Singapore',1.3644,103.9915],
  ['BKK','Bangkok','Suvarnabhumi','Thailand',13.6900,100.7501],
  ['HND','Tokyo','Haneda','Japan',35.5494,139.7798],
  ['PEK','Beijing','Capital Intl','China',40.0799,116.6031],
  ['ICN','Seoul','Incheon','South Korea',37.4602,126.4407],
  ['SYD','Sydney','Kingsford Smith','Australia',-33.9399,151.1753],
  ['AKL','Auckland','Auckland Airport','New Zealand',-37.0082,174.7850],
  ['JFK','New York','John F. Kennedy Intl','USA',40.6413,-73.7781],
  ['LAX','Los Angeles','Los Angeles Intl','USA',33.9416,-118.4085],
  ['SFO','San Francisco','San Francisco Intl','USA',37.6213,-122.3790],
  ['ORD','Chicago','O’Hare','USA',41.9742,-87.9073],
  ['YYZ','Toronto','Pearson','Canada',43.6777,-79.6248],
  ['YVR','Vancouver','Vancouver Intl','Canada',49.1967,-123.1815],
  ['MEX','Mexico City','Benito Juárez','Mexico',19.4363,-99.0721],
  ['GRU','São Paulo','Guarulhos','Brazil',-23.4356,-46.4731],
  ['JNB','Johannesburg','O. R. Tambo','South Africa',-26.1392,28.2460],
  ['CPT','Cape Town','Cape Town Intl','South Africa',-33.9715,18.6021],
  ['NBO','Nairobi','Jomo Kenyatta','Kenya',-1.3192,36.9278],
];
const byCode = Object.fromEntries(AP.map(a => [a[0], a]));

// date, from, to, airline, number, aircraft
const F = [
  ['2016-03-11','LHR','CDG','British Airways','BA304','Airbus A320neo'],
  ['2016-03-15','CDG','LHR','Air France','AF1780','Airbus A320neo'],
  ['2016-06-02','LHR','FCO','British Airways','BA550','Airbus A321neo'],
  ['2016-06-09','FCO','LHR','ITA Airways','AZ204','Airbus A320neo'],
  ['2016-09-17','LHR','DUB','Aer Lingus','EI177','Airbus A320neo'],
  ['2016-09-20','DUB','EDI','Aer Lingus','EI3246','ATR 72-600'],
  ['2016-09-22','EDI','LHR','British Airways','BA1447','Airbus A320neo'],
  ['2016-12-19','LHR','KEF','Icelandair','FI451','Boeing 737 MAX 8'],
  ['2016-12-27','KEF','LHR','Icelandair','FI450','Boeing 737 MAX 8'],
  ['2017-02-04','LHR','ZRH','Swiss','LX317','Airbus A220-300'],
  ['2017-02-08','ZRH','LHR','Swiss','LX318','Airbus A320neo'],
  ['2017-04-14','LHR','BCN','British Airways','BA478','Airbus A321neo'],
  ['2017-04-21','BCN','LIS','TAP Air Portugal','TP1039','Airbus A320neo'],
  ['2017-04-25','LIS','LHR','TAP Air Portugal','TP1358','Airbus A321neo'],
  ['2017-11-03','LHR','AMS','KLM','KL1000','Boeing 737-800'],
  ['2017-11-06','AMS','LHR','KLM','KL1017','Embraer E190'],
  ['2018-05-12','LHR','ATH','Aegean','A3609','Airbus A320neo'],
  ['2018-05-19','ATH','IST','Turkish Airlines','TK1844','Airbus A321neo'],
  ['2018-05-23','IST','LHR','Turkish Airlines','TK1979','Boeing 737 MAX 8'],
  ['2018-08-09','LHR','SIN','Singapore Airlines','SQ317','Airbus A380-800'],
  ['2018-08-16','SIN','BKK','Singapore Airlines','SQ976','Boeing 787-10'],
  ['2018-08-22','BKK','SIN','Thai Airways','TG403','Airbus A350-900'],
  ['2018-08-23','SIN','LHR','British Airways','BA012','Boeing 777-300ER'],
  ['2018-12-08','LHR','FRA','Lufthansa','LH901','Airbus A320neo'],
  ['2018-12-12','FRA','LHR','Lufthansa','LH922','Airbus A321neo'],
  ['2019-06-21','LHR','HND','British Airways','BA005','Boeing 787-9'],
  ['2019-06-28','HND','ICN','Korean Air','KE2708','Boeing 737-800'],
  ['2019-07-03','ICN','PEK','Korean Air','KE853','Airbus A330-300'],
  ['2019-07-08','PEK','LHR','British Airways','BA038','Boeing 787-9'],
  ['2019-10-05','LHR','CDG','British Airways','BA306','Airbus A320neo'],
  ['2019-10-09','CDG','LHR','Air France','AF1580','Airbus A320neo'],
  ['2021-09-14','LHR','LIS','British Airways','BA500','Airbus A320neo'],
  ['2021-09-21','LIS','LHR','TAP Air Portugal','TP1356','Airbus A321neo'],
  ['2022-05-19','LHR','JFK','British Airways','BA117','Airbus A350-1000'],
  ['2022-05-27','JFK','LAX','Delta','DL411','Airbus A321neo'],
  ['2022-06-04','LAX','LHR','Virgin Atlantic','VS008','Boeing 787-9'],
  ['2022-09-08','LHR','DOH','Qatar Airways','QR008','Airbus A350-1000'],
  ['2022-09-12','DOH','SYD','Qatar Airways','QR908','Boeing 777-300ER'],
  ['2022-09-24','SYD','AKL','Air New Zealand','NZ104','Airbus A320neo'],
  ['2022-10-02','AKL','LAX','Air New Zealand','NZ002','Boeing 787-9'],
  ['2022-10-05','LAX','LHR','British Airways','BA268','Airbus A380-800'],
  ['2023-01-19','LHR','JNB','British Airways','BA057','Airbus A380-800'],
  ['2023-01-27','JNB','CPT','South African Airways','SA341','Airbus A320neo'],
  ['2023-02-03','CPT','LHR','Virgin Atlantic','VS450','Boeing 787-9'],
  ['2023-04-13','LHR','NBO','Kenya Airways','KQ101','Boeing 787-8'],
  ['2023-04-22','NBO','LHR','British Airways','BA064','Boeing 787-9'],
  ['2023-07-06','LHR','MEX','British Airways','BA243','Boeing 787-9'],
  ['2023-07-24','MEX','LHR','British Airways','BA242','Boeing 787-9'],
  ['2023-11-09','LHR','ZRH','Swiss','LX345','Airbus A320neo'],
  ['2023-11-13','ZRH','LHR','British Airways','BA713','Airbus A320neo'],
  ['2024-05-30','LHR','AMS','KLM','KL1008','Boeing 737-800'],
  ['2024-06-02','AMS','CPH','KLM','KL1129','Embraer E195'],
  ['2024-06-06','CPH','LHR','British Airways','BA817','Airbus A320neo'],
  ['2024-11-08','LHR','FCO','British Airways','BA556','Airbus A320neo'],
  ['2024-11-13','FCO','LHR','ITA Airways','AZ206','Airbus A321neo'],
  ['2024-09-12','LHR','DEL','Virgin Atlantic','VS302','Boeing 787-9'],
  ['2024-09-20','DEL','DXB','Emirates','EK511','Boeing 777-300ER'],
  ['2024-09-24','DXB','LHR','Emirates','EK001','Airbus A380-800'],
  ['2025-01-11','LHR','KEF','Icelandair','FI451','Boeing 737 MAX 8'],
  ['2025-01-16','KEF','LHR','Icelandair','FI454','Boeing 757-200'],
  ['2025-04-05','LHR','BCN','British Airways','BA480','Airbus A321neo'],
  ['2025-04-11','BCN','FCO','ITA Airways','AZ065','Airbus A220-300'],
  ['2025-04-15','FCO','LHR','British Airways','BA553','Airbus A320neo'],
  ['2025-10-04','LHR','IST','Turkish Airlines','TK1980','Airbus A350-900'],
  ['2025-10-11','IST','ATH','Aegean','A3993','Airbus A320neo'],
  ['2025-10-15','ATH','LHR','British Airways','BA633','Airbus A321neo'],
  ['2026-05-16','LHR','YVR','British Airways','BA085','Boeing 787-9'],
  ['2026-05-25','YVR','LAX','Air Canada','AC556','Airbus A320neo'],
  ['2026-05-29','LAX','LHR','British Airways','BA269','Airbus A380-800'],
];

// CPH is referenced above; add it.
AP.push(['CPH','Copenhagen','Kastrup','Denmark',55.6180,12.6508]);
byCode.CPH = AP[AP.length - 1];

const R = Math.PI / 180;
function gc(a, b) {
  const A = byCode[a], B = byCode[b];
  if (!A || !B) throw new Error('unknown airport ' + (A ? b : a));
  const p1 = A[4] * R, p2 = B[4] * R;
  const dp = (B[4] - A[4]) * R, dl = (B[5] - A[5]) * R;
  const h = Math.sin(dp / 2) ** 2 + Math.cos(p1) * Math.cos(p2) * Math.sin(dl / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(h));
}

const flights = F.map(f => {
  const km = gc(f[1], f[2]);
  return { date: f[0], from: f[1], to: f[2], airline: f[3], number: f[4],
           aircraft: f[5], km: Math.round(km), hours: +(km / 780 + 0.45).toFixed(2) };
});

const used = new Set(flights.flatMap(f => [f.from, f.to]));
const airports = AP.filter(a => used.has(a[0]));
const countries = new Set(airports.map(a => a[3]));
const totalKm = flights.reduce((s, f) => s + f.km, 0);

const esc = s => s.replace(/\\/g, '\\\\').replace(/"/g, '\\"');
let out = `// Sample flight log bundled with the repo — invented data, not a real
// person's travel history. Swap this file for your own log to make it yours.
import Foundation

enum FlightData {
    static let airports: [Airport] = [
`;
for (const a of airports) {
  out += `    Airport(code: "${a[0]}", city: "${esc(a[1])}", name: "${esc(a[2])}", country: "${esc(a[3])}", lat: ${a[4]}, lon: ${a[5]}),\n`;
}
out += `    ]

    static let flights: [Flight] = [
`;
for (const f of flights) {
  out += `    Flight(date: "${f.date}", from: "${f.from}", to: "${f.to}", airline: "${esc(f.airline)}", number: "${f.number}", aircraft: "${esc(f.aircraft)}", km: ${f.km}, hours: ${f.hours}, note: nil),\n`;
}
out += `    ]
}
`;

fs.writeFileSync(__dirname + '/../FlightLog/FlightData.swift', out);
console.log(`flights ${flights.length} | km ${totalKm.toLocaleString()} | airports ${airports.length} | countries ${countries.size}`);
console.log(`hours ${flights.reduce((s, f) => s + f.hours, 0).toFixed(1)}`);
console.log([...countries].sort().join(', '));
