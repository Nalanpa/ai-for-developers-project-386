import "@typespec/http";
import "@typespec/rest";

using Http;
using Rest;
using Rest.Resource;

@server("http://localhost:8080", "Local development server")
@service(#{ title: "Hexlet Cal Service" })
namespace HexletCal;

// ---------- Error ----------

@doc("Error for create operations: validation failure or duplicate resource.")
@error
model CreateError {
  @statusCode _: 400 | 409;
  @doc("Error message.")
  message: string;
}

@doc("Error for read/get operations: resource not found.")
@error
model ReadError {
  @statusCode _: 404;
  @doc("Error message.")
  message: string;
}

@doc("Error for update operations: validation failure, resource not found, or conflict.")
@error
model UpdateError {
  @statusCode _: 400 | 404 | 409;
  @doc("Error message.")
  message: string;
}

@doc("Error for list operations: invalid query parameters.")
@error
model ListError {
  @statusCode _: 400;
  @doc("Error message.")
  message: string;
}

// ---------- Domain Models ----------

@doc("A calendar event type. Defines a booking category with a fixed duration in minutes.")
@resource("event-types")
model EventType {
  @key id: string;
  @doc("Human-readable name of the event type.")
  name: string;
  @doc("Detailed description of the event type.")
  description: string;
  @doc("Duration of the event in minutes.")
  @minValue(1)
  durationMinutes: int32;
}

@doc("A booking represents a reserved time slot for a specific event type.")
@resource("bookings")
model Booking {
  @key id: string;
  @doc("ID of the associated event type.")
  eventTypeId: string;
  @doc("Start time of the booking.")
  startTime: utcDateTime;
  @doc("End time of the booking (computed from the event type duration).")
  endTime: utcDateTime;
  @doc("Optional guest name.")
  guestName?: string;
  @doc("Timestamp when the booking was created.")
  createdAt: utcDateTime;
}

@doc("Represents an available time slot within the 14-day booking window.")
model AvailableSlot {
  @doc("Slot start time.")
  startTime: utcDateTime;
  @doc("Slot end time.")
  endTime: utcDateTime;
}

@doc("Request payload for creating a new booking.")
model BookingCreate {
  @doc("ID of the event type to book.")
  eventTypeId: string;
  @doc("Desired start time of the booking.")
  startTime: utcDateTime;
}

// ---------- Owner (Admin) API ----------

@doc("Admin operations for managing event types. Requires API key authentication.")
@useAuth(ApiKeyAuth<ApiKeyLocation.header, "X-API-Key">)
interface OwnerEventTypes
  extends ResourceCreate<EventType, CreateError>,
    ResourceRead<EventType, ReadError>,
    ResourceUpdate<EventType, UpdateError> {
}

@doc("Admin operations for viewing bookings. Requires API key authentication.")
@useAuth(ApiKeyAuth<ApiKeyLocation.header, "X-API-Key">)
interface OwnerBookings {
  @route("/bookings/upcoming")
  @get
  @doc("List all upcoming bookings of all event types.")
  listUpcomingBookings(): Booking[];
}

// ---------- Public Guest API ----------

@doc("Public operations for browsing event types. No authentication required.")
@useAuth(NoAuth)
interface GuestEventTypes extends ResourceList<EventType, ListError> {
}

@doc("Public operations for viewing available slots and creating bookings. No authentication required.")
@useAuth(NoAuth)
interface GuestBookings {
  @route("/slots")
  @get
  @doc("Get available time slots for the next 14 days for a given event type.")
  getAvailableSlots(
    @query eventTypeId: string,
  ): AvailableSlot[];

  @route("/bookings")
  @post
  @doc("Create a booking on an available time slot.")
  createBooking(@body body: BookingCreate): Booking;
}
