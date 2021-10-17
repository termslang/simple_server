open Lwt.Infix
open Opium

exception AuthException of string

module User = struct
  type auth = {
    username : string; [@key "username"]
    password : string; [@key "password"]
  }
  [@@deriving yojson]

  type t = auth
end


let return_body b =
  let sbb = Yojson.Safe.to_string (`Assoc [ ("result", `Bool b) ]) in
  Response.make ~body:(Body.of_string sbb) () |> Lwt.return

let handler req =
  let%lwt s = Body.to_string req.Request.body in
  let json = Yojson.Safe.from_string s in
  let check x =
    if Result.is_error x then raise (AuthException "No username password")
    else Result.get_ok x
  in
  let a = check (User.auth_of_yojson json) in
  let%lwt valid = Database.check_user a.username a.password in
  return_body valid

let safe_handler req = try handler req with _ -> return_body false

let () =
  let server_thread =
    App.empty |> App.post "/method1" safe_handler |> App.run_command'
  in
  let db_thread =
    Database.create_table () >>= fun _ ->
    Database.add_user "username" "password" >>= fun _ -> Database.add_user "admin" "admin"
  in
  match server_thread with
  | `Ok server_thread ->
      Lwt_main.at_exit (fun () ->
          Lwt.return (print_endline "Server terminated"));
      let s = Lwt.join [ server_thread; db_thread ] in
      ignore (Lwt_main.run s)
  | `Error -> exit 1
  | `Not_running -> exit 0
