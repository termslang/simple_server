# Simple HTTP server

```
dune exec ./main.exe

curl -X POST http://0.0.0.0:3000 -H "Content-Type: application/json" -d "{\"login\":\"username\",\"password\":\"password\"}"
```


*OcaML developer*
** Test task 1
- Написать http server который примет запрос вида
```
POST /method1

{
  "username": "username",
  "password": "password"
}
```

- и вернет в зависимости от корректности login и password вернет json
- правильные login и password (можно захардкодить в коде)
```
{
  "result": true  # or false
}
```

- прислать каталог с кодом который собирается через, dune build,
- можно использовать что угодно, как пример dune, lwt, cohttp, opium, yojson,...
- попробовать использовать sqlite или postgres и хранить там логин и пароль, было бы большим плюсом.
