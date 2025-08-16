class AddGraphsToOntologyAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :ontology_analyses, :applicant_graph, :jsonb
    add_column :ontology_analyses, :job_graph, :jsonb
    add_column :ontology_analyses, :company_graph, :jsonb
  end
end
