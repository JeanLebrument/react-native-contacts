jest.dontMock('../index.js');
import Contacts from '../index.js'

describe('rx_contacts', () => {
  it("should getAll contacts", function() {
    Contacts.getAll().subscribe(contacts => {
      expect(contacts).not.toBe(null);
    }, error => {
      expect(error).toBe(null);
    });
  })
});