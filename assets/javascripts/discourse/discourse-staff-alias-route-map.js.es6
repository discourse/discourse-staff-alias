export default function() {
  this.route("discourse-staff-alias", function() {
    this.route("actions", function() {
      this.route("show", { path: "/:id" });
    });
  });
};
