import { User } from "../../models/User.js";
import {
    generateToken,
    generateBait,
    generateRefreshToken,
} from "../../middleware/token/token.js";

export const login = async (req, res) => {
    try {
        const user = await User.findOne({
            username: req.body.username,
        }).select('+password')
        if (!user) {
            return res.status(403).json({
                error: {
                    source: "body/username:password",
                    detail: "Usuario y/o contraseña incorrectos.",
                }
            })
        }

        if (user.statusDB !== "active") {
            return res.status(403).json({
                error: {
                    source: "body/username:password",
                    detail: "Usuario y/o contraseña incorrectos.",
                }
            })
        }

        const passwordMatched = await user.comparePassword(req.body.password);

        if (!passwordMatched) {
            return res.status(403).json({
                error: {
                    source: "body/username:password",
                    detail: "Usuario y/o contraseña incorrectos.",
                }
            })
        }

        const { token, exp } = generateToken(user.id, user.rol)
        const bait = await generateBait();
        const refreshToken = generateRefreshToken(user.id, res)

        const dataUser = user.toObject();
        delete dataUser.password;
        delete dataUser.__v;

        return res.status(200).json({
            ok: true,
            data: {
                accessToken: token,
                exp,
                user: bait,
                dataUser,
                refreshToken,
            },
        });

    } catch (error) {
        console.error(error);
        return res.status(500).json({
            error: {
                source: "",
                detail: "Error del servidor: " + error.message,
            },
        });
    }
}