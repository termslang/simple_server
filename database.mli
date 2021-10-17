type error = Database_error of string

val create_table : unit -> unit Lwt.t
val add_user : string -> string -> unit Lwt.t
val check_user : string -> string -> bool Lwt.t
