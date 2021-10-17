(**
Usage examples:
let connection_url = "sqlite3:///Users/mb/ocaml/simple_server/credentials.db"
let connection_url = "postgresql://localhost:5432"
*)
let connection_url = "sqlite3://"

type error = Database_error of string

module Q = struct
  let create_table =
    Caqti_request.exec Caqti_type.unit
      {| CREATE TABLE users (
         username TEXT NOT NULL PRIMARY KEY,
         password TEXT NOT NULL
       )
      |}

  let add_user =
    Caqti_request.exec
      Caqti_type.(tup2 string string)
      "INSERT INTO users (username, password) VALUES (?, ?)"

  let find_user =
    Caqti_request.find_opt Caqti_type.string Caqti_type.string
      "SELECT password FROM users WHERE username = ?"
end

let pool =
  match Caqti_lwt.connect_pool (Uri.of_string connection_url) with
  | Ok pool -> pool
  | Error _ -> failwith "Error creating DB connection pool"

let or_error m =
  match%lwt m with
  | Ok a -> Ok a |> Lwt.return
  | Error e -> Error (Database_error (Caqti_error.show e)) |> Lwt.return

let create_table' () =
  let go (module C : Caqti_lwt.CONNECTION) = C.exec Q.create_table () in
  Caqti_lwt.Pool.use go pool |> or_error

let add_user' name pass =
  let go (module C : Caqti_lwt.CONNECTION) = C.exec Q.add_user (name, pass) in
  Caqti_lwt.Pool.use go pool |> or_error

let find_user name =
  let go (module C : Caqti_lwt.CONNECTION) = C.find_opt Q.find_user name in
  Caqti_lwt.Pool.use go pool |> or_error

let create_table () =
  print_endline "Creating table.";
  match%lwt create_table' () with
  | Ok () -> print_endline "Done." |> Lwt.return
  | Error (Database_error msg) -> print_endline msg |> Lwt.return

let add_user name pass =
  print_endline "Adding user.";
  match%lwt add_user' name pass with
  | Ok () -> print_endline "Done." |> Lwt.return
  | Error (Database_error msg) -> print_endline msg |> Lwt.return

let check_user name pass =
  let%lwt go = find_user name in
  match go with
  | Ok (Some a) ->
      if 0 == compare a pass then true |> Lwt.return else false |> Lwt.return
  | Ok None -> false |> Lwt.return
  | _ -> false |> Lwt.return
