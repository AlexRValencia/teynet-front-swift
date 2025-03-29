import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";

const tokenErrors = {
    "invalid signature": "La firma del JWT no es válida",
    "jwt expired": "JWT expirado",
    "invalid token": "Token invalido",
    "No Bearer": "Utiliza formato Bearer",
    "jwt malformed": "JWT formato invalido",
    "No existe el token": "No existe el token",
};

export const generateToken = (uid, rol) => {

    const expiresIn = 60 * 60 * 10;
    const payload = { uid, rol }

    try {
        const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn });
        const exp = jwt.decode(token).exp;
        return { token, exp }
    } catch (error) {
        console.error(error)
    }

}

export const generateBait = async () => {

    const payload = {
        nothing: true
    }

    try {
        const bait = jwt.sign(payload, process.env.JWT_BAIT)
        const salt = await bcrypt.genSalt(10)
        return await bcrypt.hash(bait, salt)
    } catch (error) {
        console.error(error)
    }

}

export const generateRefreshToken = (uid, res) => {

    const expiresIn = 60 * 60 * 24
    const payload = {uid}

    try {
        const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH, { expiresIn })
        return refreshToken
    } catch (error) {
        console.error(error)
    }

}