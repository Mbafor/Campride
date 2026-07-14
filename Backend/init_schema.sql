-- CampRide Database Schema
-- This SQL file creates all tables for the university shuttle tracking application

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    hashed_password VARCHAR NOT NULL,
    role VARCHAR NOT NULL CHECK (role IN ('student', 'driver', 'fleet_manager', 'super_admin')),
    is_active BOOLEAN DEFAULT TRUE,
    fcm_token VARCHAR,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- Shuttles Table
CREATE TABLE IF NOT EXISTS shuttles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    plate_number VARCHAR UNIQUE NOT NULL,
    capacity INTEGER NOT NULL,
    status VARCHAR NOT NULL CHECK (status IN ('active', 'idle', 'offline')),
    driver_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shuttles_driver_id ON shuttles(driver_id);
CREATE INDEX idx_shuttles_status ON shuttles(status);

-- Routes Table
CREATE TABLE IF NOT EXISTS routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR NOT NULL,
    start_location GEOMETRY(Point, 4326) NOT NULL,
    end_location GEOMETRY(Point, 4326) NOT NULL,
    start_name VARCHAR NOT NULL,
    end_name VARCHAR NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_routes_start_location ON routes USING GIST(start_location);
CREATE INDEX idx_routes_end_location ON routes USING GIST(end_location);

-- Stops Table
CREATE TABLE IF NOT EXISTS stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    name VARCHAR NOT NULL,
    location GEOMETRY(Point, 4326) NOT NULL,
    "order" INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_stops_route_id ON stops(route_id);
CREATE INDEX idx_stops_location ON stops USING GIST(location);
CREATE INDEX idx_stops_order ON stops(route_id, "order");

-- Trips Table
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shuttle_id UUID NOT NULL REFERENCES shuttles(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES routes(id) ON DELETE CASCADE,
    status VARCHAR NOT NULL CHECK (status IN ('active', 'completed', 'cancelled')),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP
);

CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_shuttle_id ON trips(shuttle_id);
CREATE INDEX idx_trips_route_id ON trips(route_id);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_started_at ON trips(started_at);

-- Telemetry Logs Table
CREATE TABLE IF NOT EXISTS telemetry_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    location GEOMETRY(Point, 4326) NOT NULL,
    accuracy FLOAT,
    heading FLOAT,
    timestamp TIMESTAMP NOT NULL
);

CREATE INDEX idx_telemetry_driver_id ON telemetry_logs(driver_id);
CREATE INDEX idx_telemetry_trip_id ON telemetry_logs(trip_id);
CREATE INDEX idx_telemetry_location ON telemetry_logs USING GIST(location);
CREATE INDEX idx_telemetry_timestamp ON telemetry_logs(timestamp);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    type VARCHAR NOT NULL CHECK (type IN ('shuttle_heading_your_way', 'five_stops_away', 'shuttle_nearby', 'shuttle_arrived')),
    message VARCHAR NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_trip_id ON notifications(trip_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Shuttle Requests Table
CREATE TABLE IF NOT EXISTS shuttle_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pickup_location GEOMETRY(Point, 4326) NOT NULL,
    destination_location GEOMETRY(Point, 4326) NOT NULL,
    pickup_name VARCHAR,
    destination_name VARCHAR,
    matched_trip_id UUID REFERENCES trips(id) ON DELETE SET NULL,
    status VARCHAR NOT NULL CHECK (status IN ('pending', 'matched', 'completed', 'cancelled')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_shuttle_requests_student_id ON shuttle_requests(student_id);
CREATE INDEX idx_shuttle_requests_matched_trip_id ON shuttle_requests(matched_trip_id);
CREATE INDEX idx_shuttle_requests_status ON shuttle_requests(status);
CREATE INDEX idx_shuttle_requests_pickup_location ON shuttle_requests USING GIST(pickup_location);
CREATE INDEX idx_shuttle_requests_destination_location ON shuttle_requests USING GIST(destination_location);
CREATE INDEX idx_shuttle_requests_created_at ON shuttle_requests(created_at);

-- Ride History Table
CREATE TABLE IF NOT EXISTS ride_histories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    shuttle_request_id UUID REFERENCES shuttle_requests(id) ON DELETE SET NULL,
    boarded_at TIMESTAMP,
    alighted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ride_histories_student_id ON ride_histories(student_id);
CREATE INDEX idx_ride_histories_trip_id ON ride_histories(trip_id);
CREATE INDEX idx_ride_histories_shuttle_request_id ON ride_histories(shuttle_request_id);
CREATE INDEX idx_ride_histories_created_at ON ride_histories(created_at);
