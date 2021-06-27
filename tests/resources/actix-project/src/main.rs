use std::env;
use actix_web::{web, App, HttpServer, Responder};

async fn index() -> impl Responder {
    "Hello, world!"
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let bind = match env::var("SERVICE_PORT") {
        Ok(port) => format!("127.0.0.1:{}", port),
        Err(_) => String::from("127.0.0.1:8080")
    };

    HttpServer::new(|| {
        App::new()
            .route("/", web::get().to(index))
    })
    .bind(bind)?
    .run()
    .await
}
