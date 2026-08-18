from flask import Flask, render_template, request, redirect, url_for, make_response
from datetime import datetime 
import os
import sqlite3

app = Flask(__name__)

def getDbConnection():
    connection = sqlite3.connect('hotel.db')
    connection.row_factory = sqlite3.Row
    return connection

@app.route('/')
def home():
    return render_template("home.html") 

@app.route('/get_available_rooms', methods=['GET']) 
def get_available_rooms():
    db = getDbConnection()
    bedTypes = db.execute('SELECT bedTypeId, bedTypeName FROM bed_type').fetchall()
    db.close()
    
    return render_template('reservation.html', bedTypes=bedTypes)

@app.route('/submit-booking', methods=['GET'])
def submit_booking():
    checkin_str = request.args.get('checkin')
    checkout_str = request.args.get('checkout')
    num_guests = request.args.get('numGuests')
    max_price = request.args.get('maxPrice', 1000)

    selected_bed_types = request.args.getlist('bedTypes')
    handicap = request.args.get('handicap')
    smoking = request.args.get('smoking')
    max_prox_pool = request.args.get('maxProxPool')
    max_prox_garage = request.args.get('maxProxGarage')

    checkin = datetime.strptime(checkin_str, '%Y-%m-%d').date()
    checkout = datetime.strptime(checkout_str, '%Y-%m-%d').date()
    max_price = float(max_price)

    db = getDbConnection()
    
    query = """
        SELECT DISTINCT r.roomNum, r.roomType, r.numGuests, srr.baseRoomRate,
                        w.proxPool, w.proxGarage, w.hasHandicappedAccess, sr.isSmoking
        FROM room r
        JOIN sleeping_room sr ON r.roomNum = sr.roomNum
        JOIN sleeping_room_rate srr ON r.roomNum = srr.roomNum
        JOIN wing w ON r.wingId = w.wingId
        WHERE r.numGuests >= ?
            AND srr.baseRoomRate <= ?
            AND r.roomNum NOT IN (
                SELECT res.roomNum
                FROM reservation res
                WHERE res.checkInDateTime < ?
                    AND res.checkOutDateTime > ?
            )
    """

    params = [num_guests, max_price, checkout, checkin]

    if selected_bed_types:
        placeholders = ','.join('?' * len(selected_bed_types))
        query += f"""
            AND r.roomNum IN (
                SELECT roomNum
                FROM room_bed
                WHERE bedTypeId IN ({placeholders})
            )
        """
        params.extend(selected_bed_types)

    if handicap:
        query += " AND w.hasHandicappedAccess = 1"

    if smoking:
        query += " AND sr.isSmoking = 1"

    if max_prox_pool:
        query += " AND w.proxPool <= ?"
        params.append(float(max_prox_pool))

    if max_prox_garage:
        query += " AND w.proxGarage <= ?"
        params.append(float(max_prox_garage))

    query += " ORDER BY srr.baseRoomRate ASC"

    cursor = db.execute(query, params)
    available_rooms = cursor.fetchall()

    rooms_with_beds = []
    for room in available_rooms:
        bed_query = """
            SELECT bt.bedTypeName, rb.quantity
            FROM room_bed rb
            JOIN bed_type bt ON rb.bedTypeId = bt.bedTypeId
            WHERE rb.roomNum = ?
        """
        bed_cursor = db.execute(bed_query, (room['roomNum'],))
        beds = bed_cursor.fetchall()
        
        room_dict = dict(room)
        room_dict['beds'] = beds
        rooms_with_beds.append(room_dict)

    db.close()

    return render_template('results.html',
                        rooms=rooms_with_beds,
                        checkin=checkin,
                        checkout=checkout,
                        num_guests=num_guests,
                        max_price=max_price)

@app.route('/billing', methods=['GET', 'POST'])
def billing():
    return render_template("billing.html")

@app.route('/confirmation', methods=['GET', 'POST'])
def confirmation():
    return render_template("confirmation.html")

@app.route('/queries')
def queries():
    db = getDbConnection()

    queries = {
        "avg_rate_by_wing": """
            SELECT w.wingId, ROUND(AVG(srr.baseRoomRate),2) AS avgRate
            FROM sleeping_room_rate srr
            JOIN sleeping_room sr ON srr.roomNum = sr.roomNum
            JOIN room r ON r.roomNum = sr.roomNum
            JOIN wing w ON r.wingId = w.wingId
            GROUP BY w.wingId;
        """,

        "occupied_by_floor": """
            SELECT wingId, floorNum, COUNT(*) AS occupiedRooms
            FROM room
            WHERE availabilityStatus = 'occupied'
            GROUP BY wingId, floorNum;
        """,

        "checkin_hours": """
            SELECT strftime('%H', checkInDateTime) AS hour, COUNT(*) AS numCheckins
            FROM reservation
            GROUP BY hour
            ORDER BY hour;
        """,

        "revenue_by_room": """
            SELECT roomNum, SUM(amount) AS totalRevenue
            FROM bill
            GROUP BY roomNum
            ORDER BY totalRevenue DESC;
        """,

        "customer_type_dist": """
            SELECT customerType, COUNT(*) AS numCustomers
            FROM customer
            GROUP BY customerType;
        """,

        "meeting_room_usage": """
            SELECT roomNum, COUNT(*) AS usages
            FROM event_usage_slot
            GROUP BY roomNum;
        """,

        "reservation_by_type": """
            SELECT r.roomType, COUNT(*) AS numReservations
            FROM reservation res
            JOIN room r ON res.roomNum = r.roomNum
            GROUP BY r.roomType;
        """,

        "deposit_by_month": """
            SELECT strftime('%m', receivedDate) AS month, SUM(amount) AS totalDeposits
            FROM advance_deposit
            GROUP BY month
            ORDER BY month;
        """
    }

    results = {}
    for key, sql in queries.items():
        rows = db.execute(sql).fetchall()
        results[key] = [dict(row) for row in rows]  # Convert Row → dict

    db.close()
    return render_template("queries.html", results=results)

@app.errorhandler(Exception)
def handleAllErrors(e):
    return f"<h1>Error</h1><p>{str(e)}</p>", 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    print(" Hotel Last Resort starting on port 8080")
    print("Open http://localhost:8080 in your browser")
    app.run(host='0.0.0.0', port=port, debug=True)
