-- Seed: states and union territories.
BEGIN;

INSERT INTO states (code, name, kind) VALUES
  ('AP', 'Andhra Pradesh', 'state'),
  ('AR', 'Arunachal Pradesh', 'state'),
  ('AS', 'Assam', 'state'),
  ('BR', 'Bihar', 'state'),
  ('CG', 'Chhattisgarh', 'state'),
  ('GA', 'Goa', 'state'),
  ('GJ', 'Gujarat', 'state'),
  ('HR', 'Haryana', 'state'),
  ('HP', 'Himachal Pradesh', 'state'),
  ('JH', 'Jharkhand', 'state'),
  ('KA', 'Karnataka', 'state'),
  ('KL', 'Kerala', 'state'),
  ('MP', 'Madhya Pradesh', 'state'),
  ('MH', 'Maharashtra', 'state'),
  ('MN', 'Manipur', 'state'),
  ('ML', 'Meghalaya', 'state'),
  ('MZ', 'Mizoram', 'state'),
  ('NL', 'Nagaland', 'state'),
  ('OD', 'Odisha', 'state'),
  ('PB', 'Punjab', 'state'),
  ('RJ', 'Rajasthan', 'state'),
  ('SK', 'Sikkim', 'state'),
  ('TN', 'Tamil Nadu', 'state'),
  ('TS', 'Telangana', 'state'),
  ('TR', 'Tripura', 'state'),
  ('UK', 'Uttarakhand', 'state'),
  ('UP', 'Uttar Pradesh', 'state'),
  ('WB', 'West Bengal', 'state'),
  ('AN', 'Andaman and Nicobar Islands', 'ut'),
  ('CH', 'Chandigarh', 'ut'),
  ('DN', 'Dadra and Nagar Haveli and Daman and Diu', 'ut'),
  ('DL', 'Delhi', 'ut'),
  ('JK', 'Jammu and Kashmir', 'ut'),
  ('LA', 'Ladakh', 'ut'),
  ('LD', 'Lakshadweep', 'ut'),
  ('PY', 'Puducherry', 'ut')
ON CONFLICT (code) DO NOTHING;

COMMIT;
