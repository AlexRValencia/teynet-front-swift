import * as dotenv from 'dotenv';

dotenv.config({
    //path: `.env/.env.${process.env.ENV}`
    path: `.env/.env`
});

import mongoose from "mongoose";
import Grid from "gridfs-stream";

mongoose.set("strictQuery", false);

mongoose.connect(process.env.URI_MONGODB)

const db = mongoose.connection;

let gfs;

db.once("open", () => {
    gfs = Grid(db.db, mongoose.mongo);
    gfs.collection("uploads");
})

db.on("connected", () => console.log("Connection established to DB OK"));
db.on("error", () => console.log("Connection to DB refused FAIL"));
export { gfs };