package br.com.platform.eventapi.domain;

import io.quarkus.hibernate.orm.panache.PanacheRepositoryBase;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.UUID;

@ApplicationScoped
public class CommandRepository implements PanacheRepositoryBase<CommandOutboxEntity, UUID> {
}
