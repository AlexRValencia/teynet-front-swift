import { Router } from "express";
import { login } from "../../controllers/authn/authn.js";

const router = Router();

router.post("/login", login);

export default router;