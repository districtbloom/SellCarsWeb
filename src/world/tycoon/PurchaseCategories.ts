export type PurchaseCategory = 'Money-making' | 'Cosmetic' | 'Architectural';

// These purchases decorate the business. Their original source IDs remain stable,
// but no operating capability or construction purchase depends on owning them.
export const COSMETIC_STEPS = new Set([23, 34, 57, 58, 64, 190, 194, 195, 196, 218, 222, 227, 228, 232, 239, 240]);
export const PARKING_STEPS = new Set([31, 32, 128, 133, 140, 143]);
export function purchaseCategory(step: number, title: string): PurchaseCategory {
  if (COSMETIC_STEPS.has(step)) return 'Cosmetic';
  return /workyard|canopy|slab|power|shelter|perimeter|gate|walk|hut|office|facilit|shell|enclosure|room|court|envelope|campus|pavilion|hall|architecture|garage|headquarters|crown|roof|surface|crossing|spine|fabric|safety|kiosk|parking|lockers|lounge|reception|rest point/i.test(title)
    ? 'Architectural' : 'Money-making';
}
export const padColor = (category: string) => category === 'Cosmetic' ? 0x55a8ef : 0x79d66f;
export const legacyPadCategory = (name: string): PurchaseCategory => purchaseCategory(0, name);
export const removedDisplayPart = (path: string) => /(?:SalesCar_|ElevatedSalesCar_|SalesDisplay_|Sales_Display_|First_Sale_Display|04_Sales_And_Handover\.Listing_|PersonalCar_\d+\.)/.test(path.replace(/\//g, '.'));
