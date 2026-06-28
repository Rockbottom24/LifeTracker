
ALTER TABLE food_items
ADD COLUMN barcode VARCHAR(50);

ALTER TABLE food_items
ADD COLUMN brand VARCHAR(255);

ALTER TABLE food_items
ADD COLUMN image_url TEXT;

ALTER TABLE food_items
ADD COLUMN source VARCHAR(50);

ALTER TABLE food_items
ADD CONSTRAINT uk_food_barcode
UNIQUE(barcode);