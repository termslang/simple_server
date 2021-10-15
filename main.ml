open Opium

exception AuthException of string

module Users = Map.Make (String)

let credentials = Users.add "username" "password" Users.empty
let member c k = c |> Yojson.Safe.Util.member k |> Yojson.Safe.Util.to_string

type auth = {
  username : string; [@key "username"]
  password : string; [@key "password"]
}
[@@deriving yojson]

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
  let a = check (auth_of_yojson json) in
  let valid = 0 == compare (Users.find a.username credentials) a.password in
  return_body valid

let safe_handler req = try handler req with _ -> return_body false
let _ = App.empty |> App.post "/method1" safe_handler |> App.run_command
