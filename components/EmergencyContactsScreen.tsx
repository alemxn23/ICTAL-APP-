import React, { useState } from 'react';
import { ArrowLeft, UserPlus, Trash2, Phone, Heart, Save, AlertCircle } from 'lucide-react';
import { PatientProfile, EmergencyContact } from '../types';

interface EmergencyContactsScreenProps {
  patient: PatientProfile;
  onUpdate: (updatedContacts: EmergencyContact[]) => void;
  onBack: () => void;
}

export const EmergencyContactsScreen: React.FC<EmergencyContactsScreenProps> = ({ patient, onUpdate, onBack }) => {
  const [contacts, setContacts] = useState<EmergencyContact[]>(patient.contacts);
  const [isAdding, setIsAdding] = useState(false);

  // Form State
  const [newName, setNewName] = useState('');
  const [newPhone, setNewPhone] = useState('');
  const [newRelation, setNewRelation] = useState('');
  const [error, setError] = useState('');

  const handleDelete = (id: string) => {
    const updated = contacts.filter(c => c.id !== id);
    setContacts(updated);
    onUpdate(updated);
  };

  const validatePhone = (phone: string) => {
    // Basic E.164-ish check: + followed by 10-15 digits
    const regex = /^\+?[1-9]\d{1,14}$/;
    return regex.test(phone.replace(/\s/g, ''));
  };

  const handleSave = () => {
    setError('');

    if (!newName || !newPhone || !newRelation) {
      setError('Todos los campos son obligatorios.');
      return;
    }

    if (!validatePhone(newPhone)) {
      setError('Formato inválido. Use formato internacional (ej: +34...)');
      return;
    }

    const newContact: EmergencyContact = {
      id: Date.now().toString(),
      name: newName,
      phone: newPhone,
      relation: newRelation
    };

    const updated = [...contacts, newContact];
    setContacts(updated);
    onUpdate(updated);

    // Reset form
    setIsAdding(false);
    setNewName('');
    setNewPhone('');
    setNewRelation('');
  };

  return (
    <div className="h-full flex flex-col bg-med-black text-gray-300 relative overflow-hidden">

      {/* Header */}
      <div className="flex items-center justify-between p-6 border-b border-med-gray bg-med-dark/80 backdrop-blur-md sticky top-0 z-10">
        <button
          onClick={onBack}
          className="p-2 -ml-2 rounded-full hover:bg-med-gray text-white transition-colors"
        >
          <ArrowLeft className="w-6 h-6" />
        </button>
        <div>
          <h1 className="text-xl font-bold text-white tracking-wide text-right">CÍRCULO DE SEGURIDAD</h1>
          <p className="text-[10px] text-med-red font-mono text-right uppercase">CONTACTOS SOS (MAX 5)</p>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">

        {/* Info Card */}
        <div className="bg-med-red/10 border border-med-red/30 p-4 rounded-xl flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-med-red shrink-0 mt-0.5" />
          <p className="text-xs text-gray-300 leading-relaxed">
            Estos contactos recibirán una <strong>alerta automática con su ubicación GPS</strong> si la IA detecta una crisis prolongada (&gt;5 min) o una caída severa.
          </p>
        </div>

        {/* Contact List */}
        <div className="space-y-3">
          {contacts.map((contact) => (
            <div key={contact.id} className="bg-med-dark border border-med-gray p-4 rounded-xl flex items-center justify-between group">
              <div className="flex items-center gap-4">
                <div className="w-10 h-10 rounded-full bg-gray-800 flex items-center justify-center border border-gray-700">
                  <UserPlus className="w-5 h-5 text-gray-400" />
                </div>
                <div>
                  <h3 className="text-white font-bold">{contact.name}</h3>
                  <div className="flex items-center gap-2 text-xs text-gray-400">
                    <span className="text-med-blue">{contact.relation}</span>
                    <span>•</span>
                    <span className="font-mono">{contact.phone}</span>
                  </div>
                </div>
              </div>
              <button
                onClick={() => handleDelete(contact.id)}
                className="p-2 text-gray-600 hover:text-med-red transition-colors"
              >
                <Trash2 className="w-5 h-5" />
              </button>
            </div>
          ))}

          {contacts.length === 0 && (
            <div className="text-center py-10 opacity-50">
              <Phone className="w-12 h-12 mx-auto mb-2 text-gray-600" />
              <p className="text-sm">Sin contactos configurados.</p>
            </div>
          )}
        </div>

        {/* Add Form */}
        {isAdding ? (
          <div className="bg-gray-900 border border-gray-700 p-4 rounded-xl animate-in slide-in-from-bottom duration-300">
            <h3 className="text-white font-bold mb-3 flex items-center gap-2">
              <UserPlus className="w-4 h-4 text-med-green" /> Nuevo Contacto
            </h3>

            <div className="space-y-3">
              <input
                placeholder="Nombre completo"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                className="w-full bg-black border border-gray-700 rounded-lg p-3 text-sm text-white focus:border-med-green outline-none"
              />
              <input
                placeholder="Teléfono (ej: +52 55...)"
                value={newPhone}
                type="tel"
                onChange={(e) => setNewPhone(e.target.value)}
                className="w-full bg-black border border-gray-700 rounded-lg p-3 text-sm text-white focus:border-med-green outline-none"
              />
              <input
                placeholder="Relación (ej: Madre, Doctor...)"
                value={newRelation}
                onChange={(e) => setNewRelation(e.target.value)}
                className="w-full bg-black border border-gray-700 rounded-lg p-3 text-sm text-white focus:border-med-green outline-none"
              />

              {error && <p className="text-xs text-med-red font-bold">{error}</p>}

              <div className="flex gap-3 pt-2">
                <button
                  onClick={() => setIsAdding(false)}
                  className="flex-1 py-3 rounded-lg border border-gray-700 text-gray-400 font-bold text-xs"
                >
                  CANCELAR
                </button>
                <button
                  onClick={handleSave}
                  className="flex-1 py-3 rounded-lg bg-med-green text-black font-bold text-xs hover:bg-med-green/90"
                >
                  GUARDAR
                </button>
              </div>
            </div>
          </div>
        ) : (
          contacts.length < 5 && (
            <button
              onClick={() => setIsAdding(true)}
              className="w-full py-4 border-2 border-dashed border-gray-700 rounded-xl text-gray-500 font-bold flex items-center justify-center gap-2 hover:border-gray-500 hover:text-white transition-all"
            >
              <UserPlus className="w-5 h-5" /> AÑADIR CONTACTO
            </button>
          )
        )}
      </div>
    </div>
  );
};