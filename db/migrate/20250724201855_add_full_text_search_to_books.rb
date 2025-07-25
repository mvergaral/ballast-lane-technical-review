class AddFullTextSearchToBooks < ActiveRecord::Migration[8.0]
  def up
    # Agregar columna para almacenar el vector de búsqueda
    add_column :books, :search_vector, :tsvector
    
    # Crear índice GIN para búsqueda rápida
    add_index :books, :search_vector, using: :gin
    
    # Crear función para actualizar el vector de búsqueda
    execute <<-SQL
      CREATE OR REPLACE FUNCTION books_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector :=
          setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
          setweight(to_tsvector('english', COALESCE(NEW.author, '')), 'B') ||
          setweight(to_tsvector('english', COALESCE(NEW.genre, '')), 'C') ||
          setweight(to_tsvector('english', COALESCE(NEW.isbn, '')), 'D');
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL
    
    # Crear trigger para actualizar automáticamente el vector de búsqueda
    execute <<-SQL
      CREATE TRIGGER books_search_vector_update
        BEFORE INSERT OR UPDATE ON books
        FOR EACH ROW
        EXECUTE FUNCTION books_search_vector_update();
    SQL
    
    # Actualizar todos los registros existentes
    execute <<-SQL
      UPDATE books SET search_vector = 
        setweight(to_tsvector('english', COALESCE(title, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(author, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(genre, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(isbn, '')), 'D');
    SQL
  end

  def down
    # Eliminar trigger
    execute "DROP TRIGGER IF EXISTS books_search_vector_update ON books;"
    
    # Eliminar función
    execute "DROP FUNCTION IF EXISTS books_search_vector_update();"
    
    # Eliminar índice
    remove_index :books, :search_vector
    
    # Eliminar columna
    remove_column :books, :search_vector
  end
end
