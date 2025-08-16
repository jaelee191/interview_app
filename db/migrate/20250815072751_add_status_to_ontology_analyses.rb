class AddStatusToOntologyAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :ontology_analyses, :analysis_status, :string
  end
end
