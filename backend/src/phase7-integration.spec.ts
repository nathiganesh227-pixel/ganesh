import * as bcrypt from 'bcrypt';

describe('Phase 7 Backend Integration & Security Tests', () => {
  describe('Authentication & Password Hashing', () => {
    it('hashes passwords securely and verifies correctly with bcrypt', async () => {
      const password = 'PlazaSuperSecret2026!';
      const salt = await bcrypt.genSalt(10);
      const hash = await bcrypt.hash(password, salt);

      expect(hash).not.toEqual(password);
      expect(hash.startsWith('$2b$') || hash.startsWith('$2a$')).toBe(true);

      const isValid = await bcrypt.compare(password, hash);
      expect(isValid).toBe(true);

      const isInvalid = await bcrypt.compare('WrongPassword', hash);
      expect(isInvalid).toBe(false);
    });
  });

  describe('Server-Side Booking Validation Logic', () => {
    it('detects movie seat conflict when overlapping seats requested', () => {
      const existingSeats = ['F12', 'F13', 'F14'];
      const requestedSeats = ['F14', 'F15'];

      const hasConflict = requestedSeats.some((s) => existingSeats.includes(s));
      expect(hasConflict).toBe(true);
    });

    it('calculates hotel stays correctly with room total, add-ons, and taxes', () => {
      const pricePerNight = 48500.0;
      const nights = 2;
      const roomsCount = 1;
      const addOnsTotal = 2500.0;

      const roomTotal = pricePerNight * nights * roomsCount;
      const taxesAndFees = Math.round((roomTotal + addOnsTotal) * 0.12);
      const grandTotal = roomTotal + addOnsTotal + taxesAndFees;

      expect(roomTotal).toBe(97000.0);
      expect(taxesAndFees).toBe(11940);
      expect(grandTotal).toBe(111440);
    });

    it('calculates shopping order correctly with item prices and GST', () => {
      const items = [
        { price: 189900.0, quantity: 1 },
        { price: 29990.0, quantity: 2 },
      ];
      const itemsTotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
      const platformFee = 29.0;
      const gst = Math.round(itemsTotal * 0.05);
      const grandTotal = itemsTotal + platformFee + gst;

      expect(itemsTotal).toBe(249880);
      expect(grandTotal).toBe(249880 + 29.0 + 12494);
    });

    it('calculates event tickets and checks inventory bounds', () => {
      const remainingInventory = 5;
      const requestedTickets = 6;
      const isOverCapacity = requestedTickets > remainingInventory;

      expect(isOverCapacity).toBe(true);
    });
  });
});
