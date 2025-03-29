import Material from '../../models/Material.js';
import Project from '../../models/Project.js';

// Obtener todos los materiales de un proyecto
export const getMaterials = async (req, res) => {
    try {
        const { projectId } = req.params;
        const materials = await Material.find({ project: projectId })
            .populate('createdBy', 'fullName')
            .sort({ createdAt: -1 });

        res.json({
            ok: true,
            data: materials
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al obtener los materiales',
            error: error.message
        });
    }
};

// Obtener un material específico
export const getMaterial = async (req, res) => {
    try {
        const { id } = req.params;
        const material = await Material.findById(id)
            .populate('createdBy', 'fullName');

        if (!material) {
            return res.status(404).json({
                ok: false,
                message: 'Material no encontrado'
            });
        }

        res.json({
            ok: true,
            data: material
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al obtener el material',
            error: error.message
        });
    }
};

// Crear un nuevo material
export const createMaterial = async (req, res) => {
    try {
        const { projectId } = req.params;
        const materialData = {
            ...req.body,
            project: projectId,
            createdBy: req.user.uid
        };

        const material = await Material.create(materialData);

        // Actualizar el proyecto con el nuevo material
        await Project.findByIdAndUpdate(
            projectId,
            { $push: { materials: material._id } }
        );

        res.status(201).json({
            ok: true,
            message: 'Material creado exitosamente',
            data: material
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al crear el material',
            error: error.message
        });
    }
};

// Actualizar un material
export const updateMaterial = async (req, res) => {
    try {
        const { id } = req.params;
        const material = await Material.findByIdAndUpdate(
            id,
            req.body,
            { new: true, runValidators: true }
        );

        if (!material) {
            return res.status(404).json({
                ok: false,
                message: 'Material no encontrado'
            });
        }

        res.json({
            ok: true,
            message: 'Material actualizado exitosamente',
            data: material
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al actualizar el material',
            error: error.message
        });
    }
};

// Eliminar un material
export const deleteMaterial = async (req, res) => {
    try {
        const { id, projectId } = req.params;
        const material = await Material.findByIdAndDelete(id);

        if (!material) {
            return res.status(404).json({
                ok: false,
                message: 'Material no encontrado'
            });
        }

        // Eliminar la referencia del material en el proyecto
        await Project.findByIdAndUpdate(
            projectId,
            { $pull: { materials: id } }
        );

        res.json({
            ok: true,
            message: 'Material eliminado exitosamente'
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            message: 'Error al eliminar el material',
            error: error.message
        });
    }
}; 